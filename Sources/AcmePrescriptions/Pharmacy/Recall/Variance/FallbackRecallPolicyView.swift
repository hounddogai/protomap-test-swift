import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a fallback recall policy.
    final class FallbackRecallPolicyView {
        var code: String
        var label: String
        var specialtyText: String
        var priority: String
        var checksum: String
        var maximum: String
        var floorValueText: String
        var discount: String
        var country: String
        var copay: String
        var patientRef: String
        var statusLabel: String

        init(code: String, label: String, specialtyText: String, priority: String, checksum: String, maximum: String, floorValueText: String, discount: String, country: String, copay: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.specialtyText = specialtyText
            self.priority = priority
            self.checksum = checksum
            self.maximum = maximum
            self.floorValueText = floorValueText
            self.discount = discount
            self.country = country
            self.copay = copay
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackRecallPolicyView(_ item: FallbackRecallPolicy) -> FallbackRecallPolicyView {
        return FallbackRecallPolicyView(
            code: item.code,
            label: item.label,
            specialtyText: item.specialty,
            priority: String(item.priority),
            checksum: item.checksum,
            maximum: String(format: "%.2f", item.maximum),
            floorValueText: String(format: "%.2f", item.floorValue),
            discount: String(format: "%.2f", item.discount),
            country: Kit.Text.truncate(item.country, limit: 64),
            copay: String(format: "%.2f", item.copay),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackRecallPolicyViews(_ items: [FallbackRecallPolicy]) -> [FallbackRecallPolicyView] {
        var views: [FallbackRecallPolicyView] = []
        for item in items {
            views.append(toFallbackRecallPolicyView(item))
        }
        return views
    }

    static func sumFallbackRecallPolicyView(_ view: FallbackRecallPolicyView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedPriority) + parsedMaximum + parsedFloorValue
    }
}
