import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a batched remittance target.
    final class BatchedRemittanceTargetView {
        var code: String
        var title: String
        var refillsText: String
        var ownerIDText: String
        var patientRef: String
        var graceDays: String
        var endsAtText: String
        var attempts: String
        var limitText: String
        var locale: String
        var statusLabel: String

        init(code: String, title: String, refillsText: String, ownerIDText: String, patientRef: String, graceDays: String, endsAtText: String, attempts: String, limitText: String, locale: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.refillsText = refillsText
            self.ownerIDText = ownerIDText
            self.patientRef = patientRef
            self.graceDays = graceDays
            self.endsAtText = endsAtText
            self.attempts = attempts
            self.limitText = limitText
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedRemittanceTargetView(_ item: BatchedRemittanceTarget) -> BatchedRemittanceTargetView {
        return BatchedRemittanceTargetView(
            code: item.code,
            title: item.title,
            refillsText: String(item.refills),
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 120),
            patientRef: item.patientRef,
            graceDays: String(item.graceDays),
            endsAtText: String(item.endsAt),
            attempts: String(item.attempts),
            limitText: String(item.limit),
            locale: Kit.Text.truncate(item.locale, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedRemittanceTargetViews(_ items: [BatchedRemittanceTarget]) -> [BatchedRemittanceTargetView] {
        var views: [BatchedRemittanceTargetView] = []
        for item in items {
            views.append(toBatchedRemittanceTargetView(item))
        }
        return views
    }

    static func sumBatchedRemittanceTargetView(_ view: BatchedRemittanceTargetView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedRefills) + Double(parsedGraceDays) + Double(parsedEndsAt)
    }
}
