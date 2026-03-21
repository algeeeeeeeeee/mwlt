import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { writeFileSync, readFileSync } from 'fs'
import { resolve } from 'path'

// Plugin to stamp sw.js with semver from package.json + short build hash
function swVersionPlugin() {
  return {
    name: 'sw-version-bump',
    closeBundle() {
      const pkg = JSON.parse(readFileSync(resolve(__dirname, 'package.json'), 'utf-8'))
      const version = pkg.version || '1.0.0'
      // Short 6-char hash from timestamp for cache-busting on same semver
      const buildHash = Date.now().toString(36).slice(-6)
      const cacheKey = `meowlett-v${version}-${buildHash}`

      const patchSw = (path) => {
        try {
          let sw = readFileSync(path, 'utf-8')
          sw = sw.replace(/meowlett-v[\d\w.-]+/, cacheKey)
          writeFileSync(path, sw)
          console.log(`✓ sw.js cache key: ${cacheKey} (${path})`)
        } catch(e) { /* file may not exist in dev */ }
      }

      patchSw(resolve(__dirname, 'dist/sw.js'))
      patchSw(resolve(__dirname, 'public/sw.js'))
    }
  }
}

export default defineConfig({
  plugins: [react(), swVersionPlugin()],
  build: {
    target: ['es2020', 'safari15'],
    cssTarget: 'safari15',
    outDir: 'dist',
    assetsDir: 'assets',
    rollupOptions: {
      output: {
        manualChunks: {
          react: ['react', 'react-dom'],
          lucide: ['lucide-react'],
        }
      }
    }
  },
  esbuild: {
    target: 'esnext',
    jsx: 'automatic',
  },
  server: {
    port: 5173,
    open: true,
  }
})
