module DAQ
    import NIDAQ

    """
    Start a analog task
    """
    function analog_task(file_ini_name::String, task_name::String)
        try
            ini = IniFile.Inifile()
            IniFile.read(ini, file_ini_name)

            samples_per_channel = IniFile.get(ini, task_name, 'samples_per_channel')
            number_of_channels = IniFile.get(ini, task_name, 'number_of_analog_channels')

            # Analog dev
            print("\nCreating analog task %s." % settings['name'])
            sys.stdout.flush()

            # settings
            task = NIDAQ.Task()
            task.CreateAIVoltageChan(
                settings['analog_input'].encode('utf-8'),
                **settings['parameters_create_ai']
            )
            task.CfgSampClkTiming(
                **settings['parameters_sample_clock_time_ai'])

            if 'parameters_export_signal' in settings
                for sig in settings['parameters_export_signal']
                    task.ExportSignal(**sig)
                end
            end

            if 'parameters_start_trigger' in settings
                task.CfgDigEdgeStartTrig(**settings['parameters_start_trigger'])
            end

            total_samples = pydaq.int32()
            data_size = samples_per_channel * number_of_channels

            with counter.get_lock() begin
                counter.value += 1
            end

            semaphore_dev.wait()

            print("\nStarting analog task %s." % settings['name'])
            sys.stdout.flush()

            task.StartTask()

            with counter.get_lock() begin
                counter.value -= 1
            end

            semaphore.wait()

            total_samples.value = 0

            while semaphore.is_set()
                t = time.time()

                data = np.zeros((data_size,), dtype=np.float64)

                task.ReadAnalogF64(
                    samples_per_channel,
                    10.0,
                    pydaq.DAQmx_Val_GroupByChannel,
                    data,
                    data_size,
                    pydaq.byref(total_samples),
                    None
                )
                samples_queue.put(data)

                print_detail("[II] %s ANALOG. Queue size = %s, %f" % (
                    settings['name'], samples_queue.qsize(), time.time() - t
                ))
            end
        catch err
            semaphore.clear()
        end

        samples_queue.close()
        task.StopTask()
        task.ClearTask()
    end


    function digital_task(semaphore, semaphore_dev, counter, samples_queue, settings)
        """
        Digital
        Need to start the dio task first!

        """
        try
            print("\nCreating digital task %s." % settings['name'])
            sys.stdout.flush()

            # settings
            samples_per_channel = settings['samples_per_channel']
            number_of_channels = settings['number_of_channels_di']

            total_samps = pydaq.int32()
            total_bytes = pydaq.int32()

            data_size = samples_per_channel * number_of_channels

            task = pydaq.Task()
            task.CreateDIChan(
                settings['digital_input'].encode('utf-8'),
                b'', pydaq.DAQmx_Val_ChanPerLine
            )
            task.CfgSampClkTiming(
                **settings['parameters_sample_clock_time_di']
            )

            with counter.get_lock() begin
                counter.value += 1
            end

            semaphore_dev.wait()

            print("\nStarting digital task %s." % settings['name'])
            sys.stdout.flush()

            task.StartTask()

            with counter.get_lock()
                counter.value -= 1
            end

            semaphore.wait()

            total_samps.value = 0
            total_bytes.value = 0

            while semaphore.is_set()
                t = time.time()

                data = np.zeros((data_size,), dtype=np.uint8 )

                task.ReadDigitalLines(
                    samples_per_channel,  # numSampsPerChan
                    10.0,  # timeout
                    pydaq.DAQmx_Val_GroupByChannel,  # fillMode
                    data,  # readArray
                    data_size,  # arraySizeInBytes
                    pydaq.byref(total_samps),  # sampsPerChanRead
                    pydaq.byref(total_bytes),  # numBytesPerChan
                    None  # reserved
                )
                samples_queue.put(data)

                print_detail("[II] DIGITAL %s. Queue size = %s, %f" % (
                    settings['name'], samples_queue.qsize(), time.time() - t
                ))
        catch err
            semaphore.clear()
        end

        samples_queue.close()
        task.StopTask()
        task.ClearTask()
    end


end  # module
