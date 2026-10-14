import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a rolling consent form slot.
    final class RollingConsentFormSlotView {
        var code: String
        var label: String
        var version: String
        var ownerID: String
        var batchSizeText: String
        var statusLabel: String

        init(code: String, label: String, version: String, ownerID: String, batchSizeText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.version = version
            self.ownerID = ownerID
            self.batchSizeText = batchSizeText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingConsentFormSlotView(_ item: RollingConsentFormSlot) -> RollingConsentFormSlotView {
        return RollingConsentFormSlotView(
            code: item.code,
            label: item.label,
            version: String(item.version),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 40),
            batchSizeText: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingConsentFormSlotViews(_ items: [RollingConsentFormSlot]) -> [RollingConsentFormSlotView] {
        var views: [RollingConsentFormSlotView] = []
        for item in items {
            views.append(toRollingConsentFormSlotView(item))
        }
        return views
    }

    static func sumRollingConsentFormSlotView(_ view: RollingConsentFormSlotView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedVersion) + Double(parsedBatchSize)
    }
}
