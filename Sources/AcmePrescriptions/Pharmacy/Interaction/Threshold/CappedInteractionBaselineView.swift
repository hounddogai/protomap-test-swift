import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a capped interaction baseline.
    final class CappedInteractionBaselineView {
        var codeText: String
        var titleText: String
        var externalRef: String
        var pinned: String
        var revisionText: String
        var statusLabel: String

        init(codeText: String, titleText: String, externalRef: String, pinned: String, revisionText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.externalRef = externalRef
            self.pinned = pinned
            self.revisionText = revisionText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedInteractionBaselineView(_ item: CappedInteractionBaseline) -> CappedInteractionBaselineView {
        return CappedInteractionBaselineView(
            codeText: item.code,
            titleText: item.title,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            pinned: "\(item.pinned)",
            revisionText: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedInteractionBaselineViews(_ items: [CappedInteractionBaseline]) -> [CappedInteractionBaselineView] {
        var views: [CappedInteractionBaselineView] = []
        for item in items {
            views.append(toCappedInteractionBaselineView(item))
        }
        return views
    }

    static func sumCappedInteractionBaselineView(_ view: CappedInteractionBaselineView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedRevision)
    }
}
