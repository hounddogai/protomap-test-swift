import Foundation

extension Kit.Text {
    /// Trims a value and lowers its case, so lookups ignore how people typed it.
    public static func normalize(_ s: String) -> String {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        if trimmed.count == 0 {
            return ""
        }
        return trimmed.lowercased()
    }

    /// Turns a display name into a lowercase, dash-separated key.
    public static func slugify(_ s: String) -> String {
        let parts = s.trimmingCharacters(in: .whitespaces).lowercased().components(separatedBy: " ")
        var kept: [String] = []
        for part in parts {
            if part.count > 0 {
                kept.append(part)
            }
        }
        return kept.joined(separator: "-")
    }

    /// Shortens a value to at most limit characters, marking the cut with an ellipsis.
    public static func truncate(_ s: String, limit: Int) -> String {
        if s.count <= limit {
            return s
        }
        if limit <= 3 {
            return String(s.prefix(limit))
        }
        return String(s.prefix(limit - 3)) + "..."
    }

    /// Masks all but the last keep characters, as receipts and logs show references.
    public static func maskTail(_ s: String, keep: Int) -> String {
        if s.count <= keep {
            return s
        }
        let hidden = s.count - keep
        return String(repeating: "*", count: hidden) + String(s.suffix(keep))
    }

    public static func wordCount(_ s: String) -> Int {
        var countValue = 0
        for word in s.trimmingCharacters(in: .whitespaces).components(separatedBy: " ") {
            if word.count > 0 {
                countValue += 1
            }
        }
        return countValue
    }

    /// Reports whether any of the words occurs in s, ignoring case.
    public static func containsAny(_ s: String, words: [String]) -> Bool {
        let lowered = s.lowercased()
        for word in words {
            if lowered.contains(word.lowercased()) {
                return true
            }
        }
        return false
    }

    public static func joinNonEmpty(_ parts: [String], sep: String) -> String {
        var kept: [String] = []
        for part in parts {
            let clean = part.trimmingCharacters(in: .whitespaces)
            if clean != "" {
                kept.append(clean)
            }
        }
        return kept.joined(separator: sep)
    }

    public static func firstNonEmpty(_ parts: [String]) -> String {
        for part in parts {
            if part.trimmingCharacters(in: .whitespaces) != "" {
                return part
            }
        }
        return ""
    }

    /// Pads or cuts a value to exactly width characters, for fixed-width output.
    public static func fit(_ s: String, width: Int) -> String {
        if s.count > width {
            return String(s.prefix(width))
        }
        return s + String(repeating: " ", count: Swift.max(0, width - s.count))
    }
}
