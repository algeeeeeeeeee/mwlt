// Shared small UI components used across tabs
import {
  Utensils, Car, Heart, ShoppingBag, Gamepad2, Pill, FileText, Package,
  Coffee, Pizza, Plane, Book, Music, Monitor, Gift, Dumbbell, PawPrint,
  Leaf, CircleDollarSign, Palette, Droplets, Shirt, Wrench, Film, Beer,
  Umbrella, Flower2, Banknote,
} from "../icons.jsx";
import { PRESET_ICONS } from "../constants/index.js";

export const LUCIDE_MAP = {
  utensils: Utensils, car: Car, heart: Heart, shoppingbag: ShoppingBag,
  gamepad: Gamepad2, pill: Pill, filetext: FileText, package: Package,
  coffee: Coffee, pizza: Pizza, plane: Plane, book: Book, music: Music,
  monitor: Monitor, gift: Gift, dumbbell: Dumbbell, pawprint: PawPrint,
  leaf: Leaf, dollar: CircleDollarSign, palette: Palette, droplets: Droplets,
  shirt: Shirt, wrench: Wrench, film: Film, beer: Beer, umbrella: Umbrella,
  flower: Flower2, banknote: Banknote,
};

export function Ic({ icon, size = 18, color, style = {} }) {
  const Icon = icon;
  return <Icon size={size} color={color} strokeWidth={2} style={{ flexShrink: 0, ...style }} />;
}

export const CatIcon = ({ iconKey, size = 18, color }) => {
  const Icon = LUCIDE_MAP[iconKey] || Package;
  return <Icon size={size} color={color} strokeWidth={2} style={{ flexShrink: 0 }} />;
};

export function PresetIcon({ name, size = 14, color, strokeWidth = 2 }) {
  const Icon = PRESET_ICONS[name] || Palette;
  return <Icon size={size} color={color} strokeWidth={strokeWidth} />;
}

export function SwipeRow({ children, style = {} }) {
  return (
    <div style={{ position: "relative", ...style }}>
      {children}
    </div>
  );
}
