import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge allocation.
    final class ChargeAllocationView {
        var code: String
        var label: String
        var revision: String
        var categoryText: String
        var weight: String
        var clinicianIDText: String
        var ward: String
        var attemptsText: String
        var timezone: String
        var country: String
        var statusLabel: String

        init(code: String, label: String, revision: String, categoryText: String, weight: String, clinicianIDText: String, ward: String, attemptsText: String, timezone: String, country: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.revision = revision
            self.categoryText = categoryText
            self.weight = weight
            self.clinicianIDText = clinicianIDText
            self.ward = ward
            self.attemptsText = attemptsText
            self.timezone = timezone
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toChargeAllocationView(_ item: ChargeAllocation) -> ChargeAllocationView {
        return ChargeAllocationView(
            code: item.code,
            label: item.label,
            revision: String(item.revision),
            categoryText: Kit.Text.truncate(item.category, limit: 64),
            weight: String(format: "%.2f", item.weight),
            clinicianIDText: item.clinicianID,
            ward: item.ward,
            attemptsText: String(item.attempts),
            timezone: item.timezone,
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeAllocationViews(_ items: [ChargeAllocation]) -> [ChargeAllocationView] {
        var views: [ChargeAllocationView] = []
        for item in items {
            views.append(toChargeAllocationView(item))
        }
        return views
    }

    static func sumChargeAllocationView(_ view: ChargeAllocationView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedRevision) + parsedWeight + Double(parsedAttempts)
    }
}
