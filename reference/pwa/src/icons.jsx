// Icon compatibility shim for lucide-react
// Direct named imports for optimal tree-shaking
import {
  AlarmClock, AlertCircle, AlertTriangle, Apple, ArrowDown, ArrowRight, BadgeDollarSign, BadgeInfo, Banknote, BarChart2,
  Ban, Beer, Bell, BellOff, BellRing, Book, Calculator, Calendar, Camera,
  Car, Cat, CheckCheck, CheckCircle, ChevronDown, ChevronRight, CircleDollarSign, Clock, Coffee,
  Coins, CreditCard, DollarSign, Download, Droplets, Dumbbell, Equal, FileText,
  Film, Flag, Flame, Flower2, Gamepad2, Gift, Globe, Grape, HandCoins, Hash, Heart, HeartPulse, Home,
  Image, ImagePlus, Inbox, Laptop, LayoutList, Leaf, List, Monitor,
  Moon, Music, Package, PaintRoller, Palette, PawPrint, Pencil, PiggyBank, Pill,
  Pizza, Plane, Plus, Receipt, RefreshCw, Repeat, Rocket, Save, Search,
  Settings, Share2, Shirt, ShoppingBag, SlidersHorizontal, Smartphone, Sparkles, Sun,
  Tag, Tags, Target, Trash2, TrendingUp, Umbrella, Upload, User,
  UserPlus, Users, Utensils, Wallet, Waves, WifiOff, Wind, Wrench, X,
  Zap, ZoomIn, Citrus, Star
} from 'lucide-react';

// House and ChartPie renamed/missing in some versions — safe dynamic fallback
let _House, _ChartPie;
try { const m = require('lucide-react'); _House = m.House; _ChartPie = m.ChartPie; } catch {}
const House    = _House    || Home;
const ChartPie = _ChartPie || BarChart2;

// Inline SVG fallbacks for icons not available in lucide-react 0.383.0
export const SunMoon = ({ size = 24, color = 'currentColor', strokeWidth = 2, ...props }) => (
  <svg xmlns="http://www.w3.org/2000/svg" width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" {...props}>
    <path d="M12 2v2"/>
    <path d="M14.837 16.385a6 6 0 1 1-7.223-7.222c.624-.147.97.66.715 1.248a4 4 0 0 0 5.26 5.259c.589-.255 1.396.09 1.248.715"/>
    <path d="M16 12a4 4 0 0 0-4-4"/>
    <path d="m19 5-1.256 1.256"/>
    <path d="M20 12h2"/>
  </svg>
);

export const CirclePlus = ({ size = 24, color = 'currentColor', strokeWidth = 2, ...props }) => (
  <svg xmlns="http://www.w3.org/2000/svg" width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" {...props}>
    <circle cx="12" cy="12" r="10"/>
    <path d="M8 12h8"/>
    <path d="M12 8v8"/>
  </svg>
);

export const PaintbrushVertical = ({ size = 24, color = 'currentColor', strokeWidth = 2, ...props }) => (
  <svg xmlns="http://www.w3.org/2000/svg" width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" {...props}>
    <path d="M10 2v2"/>
    <path d="M14 2v4"/>
    <path d="M17 2a1 1 0 0 1 1 1v9H6V3a1 1 0 0 1 1-1z"/>
    <path d="M6 12a1 1 0 0 0-1 1v1a2 2 0 0 0 2 2h2a1 1 0 0 1 1 1v2.9a2 2 0 1 0 4 0V17a1 1 0 0 1 1-1h2a2 2 0 0 0 2-2v-1a1 1 0 0 0-1-1"/>
  </svg>
);

export const MessageCircle = ({ size = 24, color = 'currentColor', strokeWidth = 2, ...props }) => (
  <svg xmlns="http://www.w3.org/2000/svg" width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" {...props}>
    <path d="M2.992 16.342a2 2 0 0 1 .094 1.167l-1.065 3.29a1 1 0 0 0 1.236 1.168l3.413-.998a2 2 0 0 1 1.099.092 10 10 0 1 0-4.777-4.719"/>
  </svg>
);

export const DiamondPlus = ({ size = 24, color = 'currentColor', strokeWidth = 2, ...props }) => (
  <svg xmlns="http://www.w3.org/2000/svg" width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" {...props}>
    <path d="M12 8v8"/>
    <path d="M2.7 10.3a2.41 2.41 0 0 0 0 3.41l7.59 7.59a2.41 2.41 0 0 0 3.41 0l7.59-7.59a2.41 2.41 0 0 0 0-3.41L13.7 2.71a2.41 2.41 0 0 0-3.41 0z"/>
    <path d="M8 12h8"/>
  </svg>
);

export const Smile = ({ size = 24, color = 'currentColor', strokeWidth = 2, ...props }) => (
  <svg xmlns="http://www.w3.org/2000/svg" width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" {...props}>
    <circle cx="12" cy="12" r="10"/>
    <path d="M8 14s1.5 2 4 2 4-2 4-2"/>
    <line x1="9" x2="9.01" y1="9" y2="9"/>
    <line x1="15" x2="15.01" y1="9" y2="9"/>
  </svg>
);

// Re-export all icons used in the app
export {
  AlarmClock, AlertCircle, AlertTriangle, Apple, ArrowDown, ArrowRight, BadgeDollarSign, BadgeInfo,
  Ban, Banknote, BarChart2, Beer, Bell, BellOff, BellRing, Book, Calculator, Calendar,
  Camera, Car, Cat, ChartPie, CheckCheck, CheckCircle, ChevronDown, ChevronRight,
  CircleDollarSign, Clock, Coffee, Coins, CreditCard, DollarSign, Download,
  Droplets, Dumbbell, Equal, FileText, Film, Flag, Flame, Flower2, Gamepad2, Gift,
  Globe, Grape, HandCoins, Hash, Heart, HeartPulse, Home, House, Image, ImagePlus, Inbox, Laptop,
  LayoutList, Leaf, List, Monitor, Moon, Music, Package, PaintRoller, Palette, PawPrint,
  Pencil, PiggyBank, Pill, Pizza, Plane, Plus, Receipt, RefreshCw, Repeat, Rocket, Save,
  Search, Settings, Share2, Shirt, ShoppingBag, SlidersHorizontal, Smartphone, Sparkles,
  Sun, Tag, Tags, Target, Trash2, TrendingUp, Umbrella, Upload, User, UserPlus,
  Users, Utensils, Wallet, Waves, WifiOff, Wind, Wrench, X, Zap, ZoomIn, Citrus, Star
};

// Aliases used in App.jsx
export const Calculator2 = Calculator;

export const QrCode = ({ size = 24, color = 'currentColor', strokeWidth = 2, ...props }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" {...props}>
    <rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/>
    <rect x="3" y="14" width="7" height="7"/>
    <path d="M14 14h3v3h-3zM17 17h3v3h-3zM14 20h3"/>
  </svg>
);

export const Landmark = ({ size = 24, color = 'currentColor', strokeWidth = 2, ...props }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" {...props}>
    <line x1="3" y1="22" x2="21" y2="22"/>
    <line x1="6" y1="18" x2="6" y2="11"/>
    <line x1="10" y1="18" x2="10" y2="11"/>
    <line x1="14" y1="18" x2="14" y2="11"/>
    <line x1="18" y1="18" x2="18" y2="11"/>
    <polygon points="12 2 20 7 4 7"/>
  </svg>
);
