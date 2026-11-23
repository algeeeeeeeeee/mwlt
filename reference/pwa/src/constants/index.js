import {
  PiggyBank, Smartphone, Laptop, Car, Home, Plane, Gift, Camera,
  Book, Music, Gamepad2, Heart, ShoppingBag, Dumbbell, Wallet,
  Sparkles, Leaf, Droplets, Flame, Wind, Palette, Apple, Grape, PaintRoller, Waves, Citrus, PaintbrushVertical
} from "../icons.jsx";

export const DEFAULT_CATEGORIES = {
  food:          { label: "Food & Drinks",  labelId: "Makan & Minum",    icon: "utensils",   color: "#4ade80" },
  transport:     { label: "Transport",      labelId: "Transportasi",     icon: "car",        color: "#60a5fa" },
  date:          { label: "Date",           labelId: "Date",             icon: "heart",      color: "#f9a8d4" },
  shopping:      { label: "Shopping",       labelId: "Belanja",          icon: "shoppingbag",color: "#f97316" },
  entertainment: { label: "Entertainment",  labelId: "Hiburan",          icon: "gamepad",    color: "#c084fc" },
  health:        { label: "Health",         labelId: "Kesehatan",        icon: "pill",       color: "#f87171" },
  bills:         { label: "Bills",          labelId: "Tagihan",          icon: "filetext",   color: "#fbbf24" },
  pets:          { label: "Pets",           labelId: "Hewan Peliharaan", icon: "pawprint",   color: "#fb923c" },
  other:         { label: "Other",          labelId: "Lainnya",          icon: "package",    color: "#94a3b8" },
};

export const THEME_PRESETS = [
  { id: "green",  label: "Green",  labelId: "Hijau",   primary: "#166534", accent: "#4ade80", icon: "Leaf"             },
  { id: "blue",   label: "Blue",   labelId: "Biru",    primary: "#1e3a8a", accent: "#60a5fa", icon: "Waves"            },
  { id: "purple", label: "Purple", labelId: "Ungu",    primary: "#4c1d95", accent: "#c084fc", icon: "Grape"            },
  { id: "rose",   label: "Rose",   labelId: "Merah",   primary: "#881337", accent: "#fb7185", icon: "Apple"            },
  { id: "orange", label: "Orange", labelId: "Oranye",  primary: "#7c2d12", accent: "#fb923c", icon: "Citrus"           },
  { id: "teal",   label: "Teal",   labelId: "Tosca",   primary: "#134e4a", accent: "#2dd4bf", icon: "Wind"             },
  { id: "custom", label: "Custom", labelId: "Kustom",  primary: "#166534", accent: "#4ade80", icon: "PaintbrushVertical" },
];

export const GOAL_ICONS = {
  piggy:    { Icon: PiggyBank,   label: "Tabungan"  },
  phone:    { Icon: Smartphone,  label: "HP"        },
  laptop:   { Icon: Laptop,      label: "Laptop"    },
  car:      { Icon: Car,         label: "Kendaraan" },
  home:     { Icon: Home,        label: "Rumah"     },
  plane:    { Icon: Plane,       label: "Liburan"   },
  gift:     { Icon: Gift,        label: "Hadiah"    },
  camera:   { Icon: Camera,      label: "Kamera"    },
  book:     { Icon: Book,        label: "Buku"      },
  music:    { Icon: Music,       label: "Musik"     },
  game:     { Icon: Gamepad2,    label: "Gaming"    },
  heart:    { Icon: Heart,       label: "Health"    },
  shopping: { Icon: ShoppingBag, label: "Shopping"  },
  dumbbell: { Icon: Dumbbell,    label: "Fitness"   },
  wallet:   { Icon: Wallet,      label: "Dana"      },
  star:     { Icon: Sparkles,    label: "Impian"    },
};

export const PRESET_ICONS = { Leaf, Droplets, Heart, Flame, Wind, Palette, Sparkles, Apple, Grape, PaintRoller, Waves, Citrus, PaintbrushVertical };

export const ICON_OPTIONS = [
  // Makanan & Minuman
  "utensils","coffee","pizza","beer",
  // Transportasi & Perjalanan
  "car","plane",
  // Belanja & Gaya Hidup
  "shoppingbag","shirt","palette","gift",
  // Kesehatan & Olahraga
  "heart","pill","dumbbell",
  // Keuangan
  "dollar","banknote","wallet","piggybank","trendingup","coins",
  // Rumah & Utilitas
  "home","droplets","zap","wrench","flame","wind",
  // Teknologi & Hiburan
  "monitor","smartphone","laptop","gamepad","music","film","book",
  // Alam & Hewan
  "leaf","pawprint","flower","umbrella",
  // Lain-lain
  "package","filetext","sparkles","target","repeat",
  "inbox","users","clock","calendar","alarmclock","bell","tag","receipt",
];

export const COLOR_OPTIONS = [
  "#4ade80","#86efac","#f9a8d4","#a3e635","#34d399","#6ee7b7",
  "#fbbf24","#94a3b8","#60a5fa","#f87171","#c084fc","#fb923c",
  "#38bdf8","#e879f9","#facc15"
];
