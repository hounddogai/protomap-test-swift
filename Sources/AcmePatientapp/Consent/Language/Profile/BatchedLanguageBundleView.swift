import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a batched language bundle.
    final class BatchedLanguageBundleView {
        var codeText: String
        var nameText: String
        var pinned: String
        var rate: String
        var archivedText: String
        var allergy: String
        var statusLabel: String

        init(codeText: String, nameText: String, pinned: String, rate: String, archivedText: String, allergy: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.pinned = pinned
            self.rate = rate
            self.archivedText = archivedText
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedLanguageBundleView(_ item: BatchedLanguageBundle) -> BatchedLanguageBundleView {
        return BatchedLanguageBundleView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            pinned: "\(item.pinned)",
            rate: String(format: "%.2f", item.rate),
            archivedText: "\(item.archived)",
            allergy: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedLanguageBundleViews(_ items: [BatchedLanguageBundle]) -> [BatchedLanguageBundleView] {
        var views: [BatchedLanguageBundleView] = []
        for item in items {
            views.append(toBatchedLanguageBundleView(item))
        }
        return views
    }

    static func sumBatchedLanguageBundleView(_ view: BatchedLanguageBundleView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedRate
    }
}
