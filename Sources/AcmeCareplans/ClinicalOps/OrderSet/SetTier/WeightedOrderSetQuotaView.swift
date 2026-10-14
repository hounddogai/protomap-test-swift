import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a weighted order set quota.
    final class WeightedOrderSetQuotaView {
        var code: String
        var label: String
        var rate: String
        var region: String
        var phoneText: String
        var patientRef: String
        var weight: String
        var acuity: String
        var version: String
        var statusLabel: String

        init(code: String, label: String, rate: String, region: String, phoneText: String, patientRef: String, weight: String, acuity: String, version: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.rate = rate
            self.region = region
            self.phoneText = phoneText
            self.patientRef = patientRef
            self.weight = weight
            self.acuity = acuity
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedOrderSetQuotaView(_ item: WeightedOrderSetQuota) -> WeightedOrderSetQuotaView {
        return WeightedOrderSetQuotaView(
            code: item.code,
            label: item.label,
            rate: String(format: "%.2f", item.rate),
            region: item.region,
            phoneText: item.phone,
            patientRef: item.patientRef,
            weight: String(format: "%.2f", item.weight),
            acuity: String(item.acuity),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedOrderSetQuotaViews(_ items: [WeightedOrderSetQuota]) -> [WeightedOrderSetQuotaView] {
        var views: [WeightedOrderSetQuotaView] = []
        for item in items {
            views.append(toWeightedOrderSetQuotaView(item))
        }
        return views
    }

    static func sumWeightedOrderSetQuotaView(_ view: WeightedOrderSetQuotaView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedRate + parsedWeight + Double(parsedAcuity)
    }
}
