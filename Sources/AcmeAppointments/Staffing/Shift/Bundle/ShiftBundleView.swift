import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a shift bundle.
    final class ShiftBundleView {
        var code: String
        var nameText: String
        var encounterID: String
        var createdAt: String
        var regionText: String
        var contactEmailText: String
        var copayText: String
        var weight: String
        var statusLabel: String

        init(code: String, nameText: String, encounterID: String, createdAt: String, regionText: String, contactEmailText: String, copayText: String, weight: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.encounterID = encounterID
            self.createdAt = createdAt
            self.regionText = regionText
            self.contactEmailText = contactEmailText
            self.copayText = copayText
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toShiftBundleView(_ item: ShiftBundle) -> ShiftBundleView {
        return ShiftBundleView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            encounterID: item.encounterID,
            createdAt: String(item.createdAt),
            regionText: item.region,
            contactEmailText: item.contactEmail,
            copayText: String(format: "%.2f", item.copay),
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toShiftBundleViews(_ items: [ShiftBundle]) -> [ShiftBundleView] {
        var views: [ShiftBundleView] = []
        for item in items {
            views.append(toShiftBundleView(item))
        }
        return views
    }

    static func sumShiftBundleView(_ view: ShiftBundleView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedCreatedAt) + parsedCopay + parsedWeight
    }
}
