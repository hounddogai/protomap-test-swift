import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation window.
    final class IsolationWindowView {
        var code: String
        var label: String
        var budget: String
        var currencyText: String
        var patientRef: String
        var refillsText: String
        var expiresAt: String
        var bed: String
        var specialty: String
        var statusLabel: String

        init(code: String, label: String, budget: String, currencyText: String, patientRef: String, refillsText: String, expiresAt: String, bed: String, specialty: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.budget = budget
            self.currencyText = currencyText
            self.patientRef = patientRef
            self.refillsText = refillsText
            self.expiresAt = expiresAt
            self.bed = bed
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationWindowView(_ item: IsolationWindow) -> IsolationWindowView {
        return IsolationWindowView(
            code: item.code,
            label: item.label,
            budget: String(format: "%.2f", item.budget),
            currencyText: item.currency,
            patientRef: item.patientRef,
            refillsText: String(item.refills),
            expiresAt: String(item.expiresAt),
            bed: Kit.Text.truncate(item.bed, limit: 80),
            specialty: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationWindowViews(_ items: [IsolationWindow]) -> [IsolationWindowView] {
        var views: [IsolationWindowView] = []
        for item in items {
            views.append(toIsolationWindowView(item))
        }
        return views
    }

    static func sumIsolationWindowView(_ view: IsolationWindowView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedBudget + Double(parsedRefills) + Double(parsedExpiresAt)
    }
}
