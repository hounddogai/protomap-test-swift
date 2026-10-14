import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form baseline.
    final class ConsentFormBaselineView {
        var code: String
        var name: String
        var checksum: String
        var minimumText: String
        var copay: String
        var contactEmail: String
        var floorValue: String
        var allergy: String
        var statusLabel: String

        init(code: String, name: String, checksum: String, minimumText: String, copay: String, contactEmail: String, floorValue: String, allergy: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.minimumText = minimumText
            self.copay = copay
            self.contactEmail = contactEmail
            self.floorValue = floorValue
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormBaselineView(_ item: ConsentFormBaseline) -> ConsentFormBaselineView {
        return ConsentFormBaselineView(
            code: item.code,
            name: item.name,
            checksum: item.checksum,
            minimumText: String(format: "%.2f", item.minimum),
            copay: String(format: "%.2f", item.copay),
            contactEmail: item.contactEmail,
            floorValue: String(format: "%.2f", item.floorValue),
            allergy: Kit.Text.truncate(item.allergy, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormBaselineViews(_ items: [ConsentFormBaseline]) -> [ConsentFormBaselineView] {
        var views: [ConsentFormBaselineView] = []
        for item in items {
            views.append(toConsentFormBaselineView(item))
        }
        return views
    }

    static func sumConsentFormBaselineView(_ view: ConsentFormBaselineView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedMinimum + parsedCopay + parsedFloorValue
    }
}
