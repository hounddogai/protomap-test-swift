import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a lenient follow up manifest.
    final class LenientFollowUpManifestView {
        var code: String
        var title: String
        var floorValueText: String
        var priority: String
        var unit: String
        var timezoneText: String
        var checksumText: String
        var graceDaysText: String
        var batchSizeText: String
        var description: String
        var statusLabel: String

        init(code: String, title: String, floorValueText: String, priority: String, unit: String, timezoneText: String, checksumText: String, graceDaysText: String, batchSizeText: String, description: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.floorValueText = floorValueText
            self.priority = priority
            self.unit = unit
            self.timezoneText = timezoneText
            self.checksumText = checksumText
            self.graceDaysText = graceDaysText
            self.batchSizeText = batchSizeText
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toLenientFollowUpManifestView(_ item: LenientFollowUpManifest) -> LenientFollowUpManifestView {
        return LenientFollowUpManifestView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            floorValueText: String(format: "%.2f", item.floorValue),
            priority: String(item.priority),
            unit: Kit.Text.truncate(item.unit, limit: 80),
            timezoneText: item.timezone,
            checksumText: Kit.Text.truncate(item.checksum, limit: 80),
            graceDaysText: String(item.graceDays),
            batchSizeText: String(item.batchSize),
            description: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientFollowUpManifestViews(_ items: [LenientFollowUpManifest]) -> [LenientFollowUpManifestView] {
        var views: [LenientFollowUpManifestView] = []
        for item in items {
            views.append(toLenientFollowUpManifestView(item))
        }
        return views
    }

    static func sumLenientFollowUpManifestView(_ view: LenientFollowUpManifestView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedFloorValue + Double(parsedPriority) + Double(parsedGraceDays)
    }
}
