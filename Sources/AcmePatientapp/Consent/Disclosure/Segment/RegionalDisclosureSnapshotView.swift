import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a regional disclosure snapshot.
    final class RegionalDisclosureSnapshotView {
        var code: String
        var title: String
        var phone: String
        var acuityText: String
        var unitText: String
        var minimum: String
        var budgetText: String
        var expiresAt: String
        var patientRef: String
        var statusLabel: String

        init(code: String, title: String, phone: String, acuityText: String, unitText: String, minimum: String, budgetText: String, expiresAt: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.phone = phone
            self.acuityText = acuityText
            self.unitText = unitText
            self.minimum = minimum
            self.budgetText = budgetText
            self.expiresAt = expiresAt
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalDisclosureSnapshotView(_ item: RegionalDisclosureSnapshot) -> RegionalDisclosureSnapshotView {
        return RegionalDisclosureSnapshotView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            phone: item.phone,
            acuityText: String(item.acuity),
            unitText: item.unit,
            minimum: String(format: "%.2f", item.minimum),
            budgetText: String(format: "%.2f", item.budget),
            expiresAt: String(item.expiresAt),
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalDisclosureSnapshotViews(_ items: [RegionalDisclosureSnapshot]) -> [RegionalDisclosureSnapshotView] {
        var views: [RegionalDisclosureSnapshotView] = []
        for item in items {
            views.append(toRegionalDisclosureSnapshotView(item))
        }
        return views
    }

    static func sumRegionalDisclosureSnapshotView(_ view: RegionalDisclosureSnapshotView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedAcuity) + parsedMinimum + parsedBudget
    }
}
