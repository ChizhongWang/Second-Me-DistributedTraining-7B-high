import { create } from 'zustand';
import { getTrainProgress, type TrainProgress } from '@/service/train';

export type ModelStatus = 'seed_identity' | 'memory_upload' | 'training' | 'trained' | 'running';

interface ModelState {
  status: ModelStatus;
  error: boolean;
  isServiceStarting: boolean;
  isServiceStopping: boolean;
  trainingProgress: TrainProgress;
  setStatus: (status: ModelStatus) => void;
  setError: (error: boolean) => void;
  setServiceStarting: (isStarting: boolean) => void;
  setServiceStopping: (isStopping: boolean) => void;
  setTrainingProgress: (progress: TrainProgress) => void;
  checkTrainStatus: () => Promise<void>;
  resetTrainingState: () => void;
}

const defaultTrainingProgress: TrainProgress = {
  current_stage: 'downloading_the_base_model',
  overall_progress: 0,
  stages: [
    {
      current_step: null,
      name: 'Downloading the Base Model',
      progress: 0,
      status: 'pending',
      steps: [{ completed: false, name: 'Model Download', status: 'pending' }]
    },
    {
      current_step: null,
      name: 'Activating the Memory Matrix',
      progress: 0,
      status: 'pending',
      steps: [
        { completed: false, name: 'List Documents', status: 'pending' },
        { completed: false, name: 'Generate Document Embeddings', status: 'pending' },
        { completed: false, name: 'Process Chunks', status: 'pending' },
        { completed: false, name: 'Chunk Embedding', status: 'pending' }
      ]
    },
    {
      current_step: null,
      name: 'Synthesize Your Life Narrative',
      progress: 0.0,
      status: 'pending',
      steps: [
        { completed: false, name: 'Extract Dimensional Topics', status: 'pending' },
        { completed: false, name: 'Map Your Entity Network', status: 'pending' }
      ]
    },
    {
      current_step: null,
      name: 'Prepare Training Data for Deep Comprehension',
      progress: 0.0,
      status: 'pending',
      steps: [
        { completed: false, name: 'Decode Preference Patterns', status: 'pending' },
        { completed: false, name: 'Reinforce Identity', status: 'pending' },
        { completed: false, name: 'Augment Content Retention', status: 'pending' }
      ]
    },
    {
      current_step: null,
      name: 'Training to create Second Me',
      progress: 0.0,
      status: 'pending',
      steps: [
        { completed: false, name: 'Train', status: 'pending' },
        { completed: false, name: 'Merge Weights', status: 'pending' },
        { completed: false, name: 'Convert Model', status: 'pending' }
      ]
    }
  ],
  status: 'pending'
};

export const useTrainingStore = create<ModelState>((set) => ({
  status: 'seed_identity',
  isServiceStarting: false,
  isServiceStopping: false,
  error: false,
  trainingProgress: defaultTrainingProgress,
  setStatus: (status) => set({ status }),
  setError: (error) => set({ error }),
  setServiceStarting: (isStarting) => set({ isServiceStarting: isStarting }),
  setServiceStopping: (isStopping) => set({ isServiceStopping: isStopping }),
  setTrainingProgress: (progress) => set({ trainingProgress: progress }),
  resetTrainingState: () => set({ trainingProgress: defaultTrainingProgress }),
  checkTrainStatus: async () => {
    const config = JSON.parse(localStorage.getItem('trainingConfig') || '{}');

    set({ error: false });

    try {
      const res = await getTrainProgress({
        model_name: config.baseModel || 'Qwen2.5-7B-Instruct'
      });

      if (res.data.code === 0) {
        const data = res.data.data;
        const { overall_progress } = data;

        const newProgress = data;

        if (newProgress.status === 'failed') {
          set({ error: true });
        }

        set((state) => {
          // If current status is running, keep it unchanged
          if (state.status === 'running') {
            return {
              ...state,
              trainingProgress: newProgress
            };
          }

          const newState = {
            ...state,
            trainingProgress: newProgress
          };

          // If total progress is 100%, set status to trained
          if (overall_progress === 100) {
            newState.status = 'trained';
          }
          // If there's any progress but not complete, set status to training
          else if (overall_progress > 0) {
            newState.status = 'training';
          }

          return newState;
        });
      }
    } catch (error) {
      console.error('Error checking training status:', error);
      set({ error: true });
    }
  }
}));
