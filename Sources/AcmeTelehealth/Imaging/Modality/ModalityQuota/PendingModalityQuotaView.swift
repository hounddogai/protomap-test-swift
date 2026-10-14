import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a pending modality quota.
    final class PendingModalityQuotaView {
        var code: String
        var label: String
        var capacityText: String
        var weight: String
        var dosageMg: String
        var batchSizeText: String
        var active: String
        var retries: String
        var allergy: String
        var ratio: String
        var timezone: String
        var statusLabel: String

        init(code: String, label: String, capacityText: String, weight: String, dosageMg: String, batchSizeText: String, active: String, retries: String, allergy: String, ratio: String, timezone: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.capacityText = capacityText
            self.weight = weight
            self.dosageMg = dosageMg
            self.batchSizeText = batchSizeText
            self.active = active
            self.retries = retries
            self.allergy = allergy
            self.ratio = ratio
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toPendingModalityQuotaView(_ item: PendingModalityQuota) -> PendingModalityQuotaView {
        return PendingModalityQuotaView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            capacityText: String(item.capacity),
            weight: String(format: "%.2f", item.weight),
            dosageMg: String(format: "%.2f", item.dosageMg),
            batchSizeText: String(item.batchSize),
            active: "\(item.active)",
            retries: String(item.retries),
            allergy: item.allergy,
            ratio: String(format: "%.2f", item.ratio),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingModalityQuotaViews(_ items: [PendingModalityQuota]) -> [PendingModalityQuotaView] {
        var views: [PendingModalityQuotaView] = []
        for item in items {
            views.append(toPendingModalityQuotaView(item))
        }
        return views
    }

    static func sumPendingModalityQuotaView(_ view: PendingModalityQuotaView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedCapacity) + parsedWeight + parsedDosageMg
    }
}
