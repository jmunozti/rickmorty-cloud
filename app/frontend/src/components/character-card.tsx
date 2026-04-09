"use client";

import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";

interface Character {
  id: number;
  name: string;
  status: string;
  species: string;
  image: string;
  origin: { name: string };
}

const statusColor: Record<string, string> = {
  Alive: "bg-green-100 text-green-800",
  Dead: "bg-red-100 text-red-800",
  unknown: "bg-gray-100 text-gray-800",
};

export function CharacterCard({
  character,
  isFavorite,
  onToggleFavorite,
  onClick,
}: {
  character: Character;
  isFavorite: boolean;
  onToggleFavorite: () => void;
  onClick: () => void;
}) {
  return (
    <Card className={`overflow-hidden hover:shadow-lg transition-all duration-300 hover:-translate-y-1 border-2 ${isFavorite ? "border-green-400" : "border-transparent"} bg-white dark:bg-zinc-800`}>
      <div className="relative cursor-pointer" onClick={onClick}>
        <img src={character.image} alt={character.name} width={300} height={300} className="w-full aspect-square object-cover" />
        <Badge className={`absolute top-2 right-2 ${statusColor[character.status] || statusColor.unknown}`}>
          {character.status}
        </Badge>
      </div>
      <CardContent className="p-3">
        <h3
          className="font-bold text-sm truncate text-gray-900 dark:text-zinc-100 cursor-pointer hover:text-green-700 dark:hover:text-green-400 transition-colors"
          style={{ fontFamily: "var(--font-fredoka)" }}
          onClick={onClick}
        >
          {character.name}
        </h3>
        <p className="text-xs text-gray-500 truncate">{character.species}</p>
        <p className="text-xs text-gray-400 truncate">{character.origin.name}</p>
        <Button
          size="sm"
          onClick={(e) => { e.stopPropagation(); onToggleFavorite(); }}
          className={`w-full mt-2 cursor-pointer text-xs font-semibold transition-all duration-200 ${
            isFavorite
              ? "bg-red-500 hover:bg-red-600 text-white"
              : "bg-green-500 hover:bg-green-600 text-white"
          }`}
          style={{ fontFamily: "var(--font-fredoka)" }}
        >
          {isFavorite ? "Remove" : "Add Favorite"}
        </Button>
      </CardContent>
    </Card>
  );
}
