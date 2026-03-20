// Icon shim for lucide-react — all named imports, no inline SVG fallbacks needed on 0.469+
import {
  AlarmClock, AlertCircle, AlertTriangle, Apple, ArrowDown, ArrowRight,
  BadgeDollarSign, BadgeInfo, Ban, Banknote, BarChart2,
  Beer, Bell, BellOff, BellRing, Book, Calculator, Calendar, Camera,
  Car, Cat, CheckCheck, CheckCircle, ChevronDown, ChevronRight,
  CircleDollarSign, CirclePlus, Clock, Coffee,
  Coins, CreditCard, Citrus, DiamondPlus, DollarSign, Download,
  Droplets, Dumbbell, Equal, FileText,
  Film, Flag, Flame, Flower2, Gamepad2, Gift, Globe, Grape,
  HandCoins, Hash, Heart, HeartPulse, Home, House,
  Image, ImagePlus, Inbox, Laptop, LayoutList, Leaf, List, MessageCircle, Monitor,
  Moon, Music, Package, PaintbrushVertical, PaintRoller, Palette, PawPrint,
  Pencil, PiggyBank, Pill, Pizza, Plane, Plus, Receipt,
  RefreshCw, Repeat, Rocket, Save, Search,
  Settings, Share2, Shirt, ShoppingBag, SlidersHorizontal,
  Smartphone, Smile, Sparkles, Sun, SunMoon,
  Tag, Tags, Target, Trash2, TrendingUp, Umbrella, Upload, User,
  UserPlus, Users, Utensils, Wallet, Waves, WifiOff, Wind, Wrench, X,
  Zap, ZoomIn
} from 'lucide-react';

// ChartPie safe fallback
let _ChartPie;
try { const m = require('lucide-react'); _ChartPie = m.ChartPie; } catch {}
const ChartPie = _ChartPie || BarChart2;
export { ChartPie };

export {
  AlarmClock, AlertCircle, AlertTriangle, Apple, ArrowDown, ArrowRight,
  BadgeDollarSign, BadgeInfo, Ban, Banknote, BarChart2,
  Beer, Bell, BellOff, BellRing, Book, Calculator, Calendar, Camera,
  Car, Cat, CheckCheck, CheckCircle, ChevronDown, ChevronRight,
  CircleDollarSign, CirclePlus, Clock, Coffee,
  Coins, CreditCard, Citrus, DiamondPlus, DollarSign, Download,
  Droplets, Dumbbell, Equal, FileText,
  Film, Flag, Flame, Flower2, Gamepad2, Gift, Globe, Grape,
  HandCoins, Hash, Heart, HeartPulse, Home, House,
  Image, ImagePlus, Inbox, Laptop, LayoutList, Leaf, List, MessageCircle, Monitor,
  Moon, Music, Package, PaintbrushVertical, PaintRoller, Palette, PawPrint,
  Pencil, PiggyBank, Pill, Pizza, Plane, Plus, Receipt,
  RefreshCw, Repeat, Rocket, Save, Search,
  Settings, Share2, Shirt, ShoppingBag, SlidersHorizontal,
  Smartphone, Smile, Sparkles, Sun, SunMoon,
  Tag, Tags, Target, Trash2, TrendingUp, Umbrella, Upload, User,
  UserPlus, Users, Utensils, Wallet, Waves, WifiOff, Wind, Wrench, X,
  Zap, ZoomIn
};

export const Calculator2 = Calculator;
