import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol quota.
    final class CareProtocolQuotaView {
        var codeText: String
        var label: String
        var sourceText: String
        var visitMinutes: String
        var floorValueText: String
        var currency: String
        var statusLabel: String

        init(codeText: String, label: String, sourceText: String, visitMinutes: String, floorValueText: String, currency: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.sourceText = sourceText
            self.visitMinutes = visitMinutes
            self.floorValueText = floorValueText
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolQuotaView(_ item: CareProtocolQuota) -> CareProtocolQuotaView {
        return CareProtocolQuotaView(
            codeText: item.code,
            label: item.label,
            sourceText: item.source,
            visitMinutes: String(item.visitMinutes),
            floorValueText: String(format: "%.2f", item.floorValue),
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolQuotaViews(_ items: [CareProtocolQuota]) -> [CareProtocolQuotaView] {
        var views: [CareProtocolQuotaView] = []
        for item in items {
            views.append(toCareProtocolQuotaView(item))
        }
        return views
    }

    static func sumCareProtocolQuotaView(_ view: CareProtocolQuotaView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedVisitMinutes) + parsedFloorValue
    }
}
