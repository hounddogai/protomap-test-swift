import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form mapping.
    final class ConsentFormMappingView {
        var code: String
        var label: String
        var amount: String
        var descriptionText: String
        var capacity: String
        var acuityText: String
        var checksum: String
        var statusLabel: String

        init(code: String, label: String, amount: String, descriptionText: String, capacity: String, acuityText: String, checksum: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.amount = amount
            self.descriptionText = descriptionText
            self.capacity = capacity
            self.acuityText = acuityText
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormMappingView(_ item: ConsentFormMapping) -> ConsentFormMappingView {
        return ConsentFormMappingView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            amount: String(format: "%.2f", item.amount),
            descriptionText: item.description,
            capacity: String(item.capacity),
            acuityText: String(item.acuity),
            checksum: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormMappingViews(_ items: [ConsentFormMapping]) -> [ConsentFormMappingView] {
        var views: [ConsentFormMappingView] = []
        for item in items {
            views.append(toConsentFormMappingView(item))
        }
        return views
    }

    static func sumConsentFormMappingView(_ view: ConsentFormMappingView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedAmount + Double(parsedCapacity) + Double(parsedAcuity)
    }
}
