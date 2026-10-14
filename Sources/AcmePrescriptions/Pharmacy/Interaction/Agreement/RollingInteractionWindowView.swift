import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a rolling interaction window.
    final class RollingInteractionWindowView {
        var codeText: String
        var title: String
        var sourceText: String
        var expiresAtText: String
        var margin: String
        var sequence: String
        var statusLabel: String

        init(codeText: String, title: String, sourceText: String, expiresAtText: String, margin: String, sequence: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.sourceText = sourceText
            self.expiresAtText = expiresAtText
            self.margin = margin
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toRollingInteractionWindowView(_ item: RollingInteractionWindow) -> RollingInteractionWindowView {
        return RollingInteractionWindowView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            title: Kit.Text.truncate(item.title, limit: 64),
            sourceText: Kit.Text.truncate(item.source, limit: 64),
            expiresAtText: String(item.expiresAt),
            margin: String(format: "%.2f", item.margin),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingInteractionWindowViews(_ items: [RollingInteractionWindow]) -> [RollingInteractionWindowView] {
        var views: [RollingInteractionWindowView] = []
        for item in items {
            views.append(toRollingInteractionWindowView(item))
        }
        return views
    }

    static func sumRollingInteractionWindowView(_ view: RollingInteractionWindowView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedExpiresAt) + parsedMargin + Double(parsedSequence)
    }
}
