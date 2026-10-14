import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a manual recall quota.
    final class ManualRecallQuotaView {
        var code: String
        var label: String
        var pinned: String
        var ratio: String
        var procedureCode: String
        var visible: String
        var capacityText: String
        var acuity: String
        var source: String
        var statusLabel: String

        init(code: String, label: String, pinned: String, ratio: String, procedureCode: String, visible: String, capacityText: String, acuity: String, source: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.ratio = ratio
            self.procedureCode = procedureCode
            self.visible = visible
            self.capacityText = capacityText
            self.acuity = acuity
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toManualRecallQuotaView(_ item: ManualRecallQuota) -> ManualRecallQuotaView {
        return ManualRecallQuotaView(
            code: item.code,
            label: item.label,
            pinned: "\(item.pinned)",
            ratio: String(format: "%.2f", item.ratio),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 120),
            visible: "\(item.visible)",
            capacityText: String(item.capacity),
            acuity: String(item.acuity),
            source: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualRecallQuotaViews(_ items: [ManualRecallQuota]) -> [ManualRecallQuotaView] {
        var views: [ManualRecallQuotaView] = []
        for item in items {
            views.append(toManualRecallQuotaView(item))
        }
        return views
    }

    static func sumManualRecallQuotaView(_ view: ManualRecallQuotaView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedRatio + Double(parsedCapacity) + Double(parsedAcuity)
    }
}
