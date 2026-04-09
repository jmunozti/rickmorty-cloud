"use client";

import { useEffect, useState, useCallback } from "react";
import { CharacterCard } from "@/components/character-card";
import { CharacterDetail } from "@/components/character-detail";
import { ThemeToggle } from "@/components/theme-toggle";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";

const API = process.env.NEXT_PUBLIC_API_URL || "";

interface Character {
  id: number;
  name: string;
  status: string;
  species: string;
  image: string;
  origin: { name: string };
}

interface Favorite {
  character_id: number;
  name: string;
  image: string;
}

export default function Home() {
  const [characters, setCharacters] = useState<Character[]>([]);
  const [favorites, setFavorites] = useState<Favorite[]>([]);
  const [page, setPage] = useState(1);
  const [pages, setPages] = useState(1);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(false);
  const [selectedId, setSelectedId] = useState<number | null>(null);

  const fetchCharacters = useCallback(async () => {
    setLoading(true);
    try {
      const url = search
        ? `${API}/api/characters?name=${encodeURIComponent(search)}`
        : `${API}/api/characters?page=${page}`;
      const res = await fetch(url);
      const data = await res.json();
      setCharacters(data.results || []);
      setPages(data.info?.pages || 1);
    } catch {
      setCharacters([]);
    }
    setLoading(false);
  }, [page, search]);

  const fetchFavorites = useCallback(async () => {
    try {
      const res = await fetch(`${API}/api/favorites`);
      const data = await res.json();
      setFavorites(Array.isArray(data) ? data : []);
    } catch {
      setFavorites([]);
    }
  }, []);

  useEffect(() => {
    fetchCharacters();
    fetchFavorites();
  }, [fetchCharacters, fetchFavorites]);

  async function addFavorite(id: number, name: string, image: string) {
    await fetch(`${API}/api/favorites`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ character_id: id, name, image }),
    });
    fetchFavorites();
  }

  async function removeFavorite(id: number) {
    await fetch(`${API}/api/favorites/${id}`, { method: "DELETE" });
    fetchFavorites();
  }

  async function toggleFavoriteFromCard(c: Character) {
    if (isFavorite(c.id)) {
      await removeFavorite(c.id);
    } else {
      await addFavorite(c.id, c.name, c.image);
    }
  }

  function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    setPage(1);
    fetchCharacters();
  }

  const isFavorite = (id: number) => favorites.some((f) => f.character_id === id);

  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      <ThemeToggle />
      <div className="text-center mb-8 animate-fade-in">
        <h1 className="text-5xl font-bold text-green-700 dark:text-green-400 mb-2" style={{ fontFamily: "var(--font-fredoka)" }}>
          Rick and Morty Explorer
        </h1>
        <p className="text-lg text-cyan-700 dark:text-cyan-400" style={{ fontFamily: "var(--font-fredoka)" }}>
          Browse characters, search, and save your favorites
        </p>
        <Badge variant="secondary" className="mt-2 bg-purple-100 text-purple-700 dark:bg-purple-900 dark:text-purple-300">
          Deployed on AWS EKS with Terraform
        </Badge>
      </div>

      <form onSubmit={handleSearch} className="flex gap-2 max-w-md mx-auto mb-8">
        <Input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search characters..."
          className="bg-white dark:bg-zinc-800 border-green-200 dark:border-zinc-700 focus:border-green-400"
        />
        <Button type="submit" className="bg-green-600 hover:bg-green-700 cursor-pointer" style={{ fontFamily: "var(--font-fredoka)" }}>
          Search
        </Button>
        {search && (
          <Button type="button" variant="outline" className="cursor-pointer" onClick={() => { setSearch(""); setPage(1); }}>
            Clear
          </Button>
        )}
      </form>

      {favorites.length > 0 && (
        <div className="mb-8 animate-fade-in">
          <h2 className="text-2xl font-bold text-purple-700 mb-3" style={{ fontFamily: "var(--font-fredoka)" }}>
            Favorites ({favorites.length})
          </h2>
          <div className="flex gap-3 flex-wrap">
            {favorites.map((f) => (
              <div
                key={f.character_id}
                onClick={() => setSelectedId(f.character_id)}
                className="bg-white dark:bg-zinc-800 rounded-xl p-2 shadow-sm text-center w-24 hover:scale-110 transition-transform duration-200 border border-purple-100 dark:border-zinc-700 cursor-pointer"
              >
                <img src={f.image} alt={f.name} width={64} height={64} className="rounded-full mx-auto" />
                <p className="text-xs mt-1 text-purple-800 font-medium truncate">{f.name}</p>
              </div>
            ))}
          </div>
        </div>
      )}

      {loading && (
        <div className="text-center py-12">
          <div className="inline-block animate-spin text-4xl">🌀</div>
          <p className="text-green-600 mt-2" style={{ fontFamily: "var(--font-fredoka)" }}>Loading...</p>
        </div>
      )}

      {!loading && (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
          {characters.map((c, i) => (
            <div key={c.id} className="animate-fade-in" style={{ animationDelay: `${i * 50}ms` }}>
              <CharacterCard
                character={c}
                isFavorite={isFavorite(c.id)}
                onToggleFavorite={() => toggleFavoriteFromCard(c)}
                onClick={() => setSelectedId(c.id)}
              />
            </div>
          ))}
        </div>
      )}

      {!loading && characters.length === 0 && (
        <div className="text-center py-16">
          <p className="text-4xl mb-2">🛸</p>
          <p className="text-gray-500" style={{ fontFamily: "var(--font-fredoka)" }}>No characters found</p>
        </div>
      )}

      {!search && (
        <div className="flex justify-center items-center gap-4 mt-8">
          <Button variant="outline" disabled={page <= 1} onClick={() => setPage(page - 1)} className="cursor-pointer">
            Previous
          </Button>
          <span className="text-sm text-gray-500">Page {page} of {pages}</span>
          <Button variant="outline" disabled={page >= pages} onClick={() => setPage(page + 1)} className="cursor-pointer">
            Next
          </Button>
        </div>
      )}

      {/* Copyright */}
      <footer className="mt-12 py-6 text-center border-t border-gray-200 dark:border-zinc-800">
        <p className="text-xs text-gray-400 dark:text-zinc-500 max-w-lg mx-auto">
          Rick and Morty is created by Justin Roiland and Dan Harmon for Adult Swim.
          The data and images are used without claim of ownership and belong to their respective owners.
          Data provided by <a href="https://rickandmortyapi.com" target="_blank" rel="noopener noreferrer" className="underline hover:text-green-600">rickandmortyapi.com</a>.
        </p>
      </footer>

      <CharacterDetail
        characterId={selectedId}
        open={selectedId !== null}
        onClose={() => setSelectedId(null)}
        isFavorite={selectedId ? isFavorite(selectedId) : false}
        onAddFavorite={addFavorite}
        onRemoveFavorite={removeFavorite}
      />
    </div>
  );
}
