"use client";

import { useEffect, useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { Progress } from "@/components/ui/progress";

const API = process.env.NEXT_PUBLIC_API_URL || "";

interface CharacterData {
  id: number;
  name: string;
  status: string;
  species: string;
  type: string;
  gender: string;
  origin: { name: string };
  location: { name: string };
  image: string;
  episode: string[];
  created: string;
}

const statusConfig: Record<string, { emoji: string; color: string }> = {
  Alive: { emoji: "🟢", color: "bg-green-100 text-green-800" },
  Dead: { emoji: "🔴", color: "bg-red-100 text-red-800" },
  unknown: { emoji: "⚪", color: "bg-gray-100 text-gray-800" },
};

export function CharacterDetail({
  characterId,
  open,
  onClose,
  isFavorite,
  onAddFavorite,
  onRemoveFavorite,
}: {
  characterId: number | null;
  open: boolean;
  onClose: () => void;
  isFavorite: boolean;
  onAddFavorite: (id: number, name: string, image: string) => void;
  onRemoveFavorite: (id: number) => void;
}) {
  const [character, setCharacter] = useState<CharacterData | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!characterId || !open) return;
    setLoading(true);
    fetch(`${API}/api/characters/${characterId}`)
      .then((r) => r.json())
      .then((data) => setCharacter(data))
      .catch(() => setCharacter(null))
      .finally(() => setLoading(false));
  }, [characterId, open]);

  function handleToggle() {
    if (!character) return;
    if (isFavorite) {
      onRemoveFavorite(character.id);
    } else {
      onAddFavorite(character.id, character.name, character.image);
    }
  }

  const cfg = character ? statusConfig[character.status] || statusConfig.unknown : statusConfig.unknown;
  const episodeCount = character?.episode?.length || 0;
  const maxEpisodes = 51;

  return (
    <Dialog open={open} onOpenChange={(v) => !v && onClose()}>
      <DialogContent className="sm:max-w-[700px] bg-white dark:bg-zinc-900 p-0 overflow-hidden">
        {loading && (
          <div className="flex items-center justify-center py-20">
            <div className="inline-block animate-spin text-4xl">🌀</div>
          </div>
        )}
        {character && !loading && (
          <div className="flex flex-col sm:flex-row">
            {/* Left: Image */}
            <div className="sm:w-[280px] flex-shrink-0">
              <img
                src={character.image}
                alt={character.name}
                width={300}
                height={300}
                className="w-full h-auto sm:h-full object-cover"
              />
            </div>

            {/* Right: Info */}
            <div className="flex-1 p-6 space-y-4">
              <DialogHeader>
                <DialogTitle
                  className="text-2xl text-green-700 dark:text-green-400"
                  style={{ fontFamily: "var(--font-fredoka)" }}
                >
                  {character.name}
                </DialogTitle>
              </DialogHeader>

              <div className="flex flex-wrap items-center gap-2">
                <span>{cfg.emoji}</span>
                <Badge className={cfg.color}>{character.status}</Badge>
                <Badge variant="secondary">{character.species}</Badge>
                <Badge variant="secondary">{character.gender}</Badge>
                {character.type && (
                  <Badge variant="outline" className="text-xs">{character.type}</Badge>
                )}
              </div>

              <div className="text-sm space-y-2 text-gray-700 dark:text-gray-300">
                <p><span className="font-semibold">Origin:</span> {character.origin.name}</p>
                <p><span className="font-semibold">Location:</span> {character.location.name}</p>
                <p><span className="font-semibold">First seen:</span> {new Date(character.created).toLocaleDateString()}</p>
              </div>

              <Separator />

              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="font-semibold text-gray-700 dark:text-gray-300" style={{ fontFamily: "var(--font-fredoka)" }}>
                    Episodes
                  </span>
                  <span className="text-green-700 dark:text-green-400 font-bold">{episodeCount} / {maxEpisodes}</span>
                </div>
                <Progress value={(episodeCount / maxEpisodes) * 100} className="h-3" />
                <p className="text-xs text-gray-400">
                  {Math.round((episodeCount / maxEpisodes) * 100)}% of all episodes
                </p>
              </div>

              <Button
                onClick={handleToggle}
                className={`w-full cursor-pointer ${
                  isFavorite
                    ? "bg-red-500 hover:bg-red-600 text-white"
                    : "bg-green-500 hover:bg-green-600 text-white"
                }`}
                style={{ fontFamily: "var(--font-fredoka)" }}
              >
                {isFavorite ? "Remove from Favorites" : "Add to Favorites"}
              </Button>
            </div>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
