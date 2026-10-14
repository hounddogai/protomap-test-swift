import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a shift baseline.
    final class ShiftBaselineView {
        var code: String
        var title: String
        var expiresAt: String
        var attemptsText: String
        var ownerIDText: String
        var pinned: String
        var retriesText: String
        var maximum: String
        var nameText: String
        var amount: String
        var statusLabel: String

        init(code: String, title: String, expiresAt: String, attemptsText: String, ownerIDText: String, pinned: String, retriesText: String, maximum: String, nameText: String, amount: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.attemptsText = attemptsText
            self.ownerIDText = ownerIDText
            self.pinned = pinned
            self.retriesText = retriesText
            self.maximum = maximum
            self.nameText = nameText
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toShiftBaselineView(_ item: ShiftBaseline) -> ShiftBaselineView {
        return ShiftBaselineView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            expiresAt: String(item.expiresAt),
            attemptsText: String(item.attempts),
            ownerIDText: item.ownerID,
            pinned: "\(item.pinned)",
            retriesText: String(item.retries),
            maximum: String(format: "%.2f", item.maximum),
            nameText: item.name,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toShiftBaselineViews(_ items: [ShiftBaseline]) -> [ShiftBaselineView] {
        var views: [ShiftBaselineView] = []
        for item in items {
            views.append(toShiftBaselineView(item))
        }
        return views
    }

    static func sumShiftBaselineView(_ view: ShiftBaselineView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedAttempts) + Double(parsedRetries)
    }
}
