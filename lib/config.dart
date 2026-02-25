// ─────────────────────────────────────────────────────────────────────────────
// Configuration de l'API PestAI
// Remplace kApiBaseUrl par l'URL Railway après déploiement.
// ─────────────────────────────────────────────────────────────────────────────

const String kApiBaseUrl = 'https://pestai-gblack98.vercel.app';
const Duration kRequestTimeout = Duration(seconds: 90);

// ─── Space HuggingFace xTTS GalsenAI (TTS Wolof, gratuit ZeroGPU) ───────────
const String kHfSpaceBaseUrl =
    'https://dofbi-galsenai-xtts-v2-wolof-inference.hf.space';

// Audio de référence Wolof (voix féminine GalsenAI, utilisée pour le clonage)
const String kWolofReferenceAudioUrl =
    'https://huggingface.co/galsenai/xTTS-v2-wolof/resolve/main/anta_sample.wav';

// Timeout pour la synthèse vocale (ZeroGPU peut avoir une file d'attente)
const Duration kTtsTimeout = Duration(seconds: 120);
