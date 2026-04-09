import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  images: {
    remotePatterns: [
      { protocol: "https", hostname: "rickandmortyapi.com" },
    ],
  },
};

export default nextConfig;
