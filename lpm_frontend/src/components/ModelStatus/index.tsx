import { useTrainingStore } from '@/store/useTrainingStore';
import { startService, stopService, getServiceStatus } from '@/service/train';
import { StatusBar } from '../StatusBar';
import { useRef, useEffect, useState, useMemo } from 'react';
import { message } from 'antd';
import {
  CloudUploadOutlined,
  CheckCircleOutlined,
  PlayCircleOutlined,
  PauseCircleOutlined,
  LoadingOutlined
} from '@ant-design/icons';
import RegisterUploadModal from '../upload/RegisterUploadModal';

import { useLoadInfoStore } from '@/store/useLoadInfoStore';

const StatusDot = ({ active }: { active: boolean }) => (
  <div
    className={`w-2 h-2 rounded-full mr-2 transition-colors duration-300 ${active ? 'bg-[#52c41a]' : 'bg-[#ff4d4f]'}`}
  />
);

export function ModelStatus() {
  const status = useTrainingStore((state) => state.status);
  const setStatus = useTrainingStore((state) => state.setStatus);
  const isServiceStarting = useTrainingStore((state) => state.isServiceStarting);
  const isServiceStopping = useTrainingStore((state) => state.isServiceStopping);
  const setServiceStarting = useTrainingStore((state) => state.setServiceStarting);
  const setServiceStopping = useTrainingStore((state) => state.setServiceStopping);

  const [messageApi, contextHolder] = message.useMessage();

  const loadInfo = useLoadInfoStore((state) => state.loadInfo);
  const isRegistered = useMemo(() => {
    return loadInfo?.status === 'online';
  }, [loadInfo]);

  const [showRegisterModal, setShowRegisterModal] = useState(false);

  const handleRegistryClick = () => {
    if (status !== 'trained' && status !== 'running') {
      messageApi.info({
        content: 'Please train your model first',
        duration: 1
      });
    } else if (status === 'trained') {
      messageApi.info({
        content: 'Please start your model service first',
        duration: 1
      });
    } else if (status === 'running') {
      setShowRegisterModal(true);
    }
  };

  const fetchServiceStatus = async () => {
    try {
      const statusRes = await getServiceStatus();

      if (statusRes.data.code === 0) {
        const isRunning = statusRes.data.data.is_running;

        if (isRunning) {
          setStatus('running');
          setServiceStarting(false);
        } else if (status === 'running') {
          setStatus('trained');
        }
      }
    } catch (error) {
      console.error('Error checking initial service status:', error);
    }
  };

  useEffect(() => {
    fetchServiceStatus();

    return () => {
      clearPolling();
    };
  }, []);

  const pollingInterval = useRef<NodeJS.Timeout | null>(null);

  const clearPolling = () => {
    if (pollingInterval.current) {
      clearInterval(pollingInterval.current);
      pollingInterval.current = null;
    }
  };

  const startPolling = () => {
    clearPolling();

    // Start new polling interval
    pollingInterval.current = setInterval(() => {
      getServiceStatus()
        .then((statusRes) => {
          if (statusRes.data.code === 0) {
            const isRunning = statusRes.data.data.is_running;

            if (isRunning) {
              setStatus('running');
              setServiceStarting(false);
              clearPolling();
            }
          }
        })
        .catch((error) => {
          console.error('Error checking service status:', error);
        });
    }, 3000);
  };

  const startStopPolling = () => {
    clearPolling();

    // Start new polling interval
    pollingInterval.current = setInterval(() => {
      getServiceStatus()
        .then((statusRes) => {
          if (statusRes.data.code === 0) {
            const isRunning = statusRes.data.data.is_running;

            if (!isRunning) {
              setStatus('trained');
              setServiceStopping(false);
              clearPolling();
            }
          }
        })
        .catch((error) => {
          console.error('Error checking service status:', error);
        });
    }, 3000);
  };

  const handleServiceAction = () => {
    const config = JSON.parse(localStorage.getItem('trainingConfig') || '{}');

    if (status === 'running') {
      setServiceStopping(true);
      stopService()
        .then((res) => {
          if (res.data.code === 0) {
            messageApi.success({ content: 'Service stopping...', duration: 1 });
            startStopPolling();
          } else {
            messageApi.error({ content: res.data.message!, duration: 1 });
            setServiceStopping(false);
          }
        })
        .catch((error) => {
          console.error('Error stopping service:', error);
          messageApi.error({
            content: error.response?.data?.message || error.message,
            duration: 1
          });
          setServiceStopping(false);
        });
    } else {
      setServiceStarting(true);
      startService({ model_name: config.baseModel || 'Qwen2.5-7B-Instruct' })
        .then((res) => {
          if (res.data.code === 0) {
            messageApi.success({ content: 'Service starting...', duration: 1 });
            startPolling();
          } else {
            setServiceStarting(false);
            messageApi.error({ content: res.data.message!, duration: 1 });
          }
        })
        .catch((error) => {
          console.error('Error starting service:', error);
          setServiceStarting(false);
          messageApi.error({
            content: error.response?.data?.message || error.message,
            duration: 1
          });
        });
    }
  };

  return (
    <div className="flex items-center justify-center gap-4 mx-auto">
      {contextHolder}
      <StatusBar status={status} />

      <div className="flex items-center gap-6">
        {/* Control Buttons */}
        <div className="flex items-center gap-3">
          <div
            className={`
              flex items-center space-x-1.5 text-sm whitespace-nowrap
              ${
                isServiceStarting || isServiceStopping
                  ? 'text-gray-400 cursor-not-allowed'
                  : 'text-gray-600 hover:text-blue-600 cursor-pointer transition-all hover:-translate-y-0.5'
              }
            `}
            onClick={isServiceStarting || isServiceStopping ? undefined : handleServiceAction}
          >
            {isServiceStarting || isServiceStopping ? (
              <>
                <LoadingOutlined className="text-lg" spin />
                <span>{isServiceStarting ? 'Starting...' : 'Stopping...'}</span>
              </>
            ) : status === 'running' ? (
              <>
                <StatusDot active={true} />
                <PauseCircleOutlined className="text-lg" />
                <span>Stop Service</span>
              </>
            ) : (
              <>
                <StatusDot active={false} />
                <PlayCircleOutlined className="text-lg" />
                <span>Start Service</span>
              </>
            )}
          </div>

          <div className="w-px h-4 bg-gray-200" />

          <div
            className="flex items-center whitespace-nowrap space-x-1.5 text-sm text-gray-600 hover:text-blue-600 cursor-pointer transition-all hover:-translate-y-0.5 mr-2"
            onClick={handleRegistryClick}
          >
            {isRegistered ? (
              <>
                <StatusDot active={true} />
                <CheckCircleOutlined className="text-lg" />
                <span>Join AI Network</span>
              </>
            ) : (
              <>
                <StatusDot active={false} />
                <CloudUploadOutlined className="text-lg" />
                <span>Join AI Network</span>
              </>
            )}
          </div>
        </div>
      </div>

      <RegisterUploadModal onClose={() => setShowRegisterModal(false)} open={showRegisterModal} />
    </div>
  );
}
