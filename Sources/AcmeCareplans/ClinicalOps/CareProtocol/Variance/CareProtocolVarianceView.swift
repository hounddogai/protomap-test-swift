import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol variance.
    final class CareProtocolVarianceView {
        var code: String
        var nameText: String
        var capacity: String
        var locale: String
        var expiresAt: String
        var floorValue: String
        var budget: String
        var specialty: String
        var statusLabel: String

        init(code: String, nameText: String, capacity: String, locale: String, expiresAt: String, floorValue: String, budget: String, specialty: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.capacity = capacity
            self.locale = locale
            self.expiresAt = expiresAt
            self.floorValue = floorValue
            self.budget = budget
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolVarianceView(_ item: CareProtocolVariance) -> CareProtocolVarianceView {
        return CareProtocolVarianceView(
            code: item.code,
            nameText: item.name,
            capacity: String(item.capacity),
            locale: item.locale,
            expiresAt: String(item.expiresAt),
            floorValue: String(format: "%.2f", item.floorValue),
            budget: String(format: "%.2f", item.budget),
            specialty: Kit.Text.truncate(item.specialty, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolVarianceViews(_ items: [CareProtocolVariance]) -> [CareProtocolVarianceView] {
        var views: [CareProtocolVarianceView] = []
        for item in items {
            views.append(toCareProtocolVarianceView(item))
        }
        return views
    }

    static func sumCareProtocolVarianceView(_ view: CareProtocolVarianceView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedCapacity) + Double(parsedExpiresAt) + parsedFloorValue
    }
}
