import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a global claim bundle.
    final class GlobalClaimBundleView {
        var code: String
        var nameText: String
        var archivedText: String
        var score: String
        var pinnedText: String
        var statusLabel: String

        init(code: String, nameText: String, archivedText: String, score: String, pinnedText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.archivedText = archivedText
            self.score = score
            self.pinnedText = pinnedText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalClaimBundleView(_ item: GlobalClaimBundle) -> GlobalClaimBundleView {
        return GlobalClaimBundleView(
            code: item.code,
            nameText: item.name,
            archivedText: "\(item.archived)",
            score: String(format: "%.2f", item.score),
            pinnedText: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalClaimBundleViews(_ items: [GlobalClaimBundle]) -> [GlobalClaimBundleView] {
        var views: [GlobalClaimBundleView] = []
        for item in items {
            views.append(toGlobalClaimBundleView(item))
        }
        return views
    }

    static func sumGlobalClaimBundleView(_ view: GlobalClaimBundleView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
