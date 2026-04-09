"use client";

import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";

export function ThemeToggle() {
  const [dark, setDark] = useState(false);

  useEffect(() => {
    const saved = localStorage.getItem("theme");
    if (saved === "dark") {
      setDark(true);
      document.documentElement.classList.add("dark");
    }
  }, []);

  function toggle() {
    const next = !dark;
    setDark(next);
    if (next) {
      document.documentElement.classList.add("dark");
      localStorage.setItem("theme", "dark");
    } else {
      document.documentElement.classList.remove("dark");
      localStorage.setItem("theme", "light");
    }
  }

  return (
    <Button
      variant="outline"
      size="sm"
      onClick={toggle}
      className="cursor-pointer fixed top-4 right-4 z-50 bg-white/80 dark:bg-zinc-800/80 backdrop-blur-sm"
    >
      {dark ? "☀️ Light" : "🌙 Dark"}
    </Button>
  );
}
