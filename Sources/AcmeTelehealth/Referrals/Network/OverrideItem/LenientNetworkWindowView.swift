import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a lenient network window.
    final class LenientNetworkWindowView {
        var codeText: String
        var title: String
        var unit: String
        var approved: String
        var threshold: String
        var pinned: String
        var nameText: String
        var attempts: String
        var minimum: String
        var statusLabel: String

        init(codeText: String, title: String, unit: String, approved: String, threshold: String, pinned: String, nameText: String, attempts: String, minimum: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.unit = unit
            self.approved = approved
            self.threshold = threshold
            self.pinned = pinned
            self.nameText = nameText
            self.attempts = attempts
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toLenientNetworkWindowView(_ item: LenientNetworkWindow) -> LenientNetworkWindowView {
        return LenientNetworkWindowView(
            codeText: item.code,
            title: item.title,
            unit: item.unit,
            approved: "\(item.approved)",
            threshold: String(format: "%.2f", item.threshold),
            pinned: "\(item.pinned)",
            nameText: Kit.Text.truncate(item.name, limit: 64),
            attempts: String(item.attempts),
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientNetworkWindowViews(_ items: [LenientNetworkWindow]) -> [LenientNetworkWindowView] {
        var views: [LenientNetworkWindowView] = []
        for item in items {
            views.append(toLenientNetworkWindowView(item))
        }
        return views
    }

    static func sumLenientNetworkWindowView(_ view: LenientNetworkWindowView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedThreshold + Double(parsedAttempts) + parsedMinimum
    }
}
