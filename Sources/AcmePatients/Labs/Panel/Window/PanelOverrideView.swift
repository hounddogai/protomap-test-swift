import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel override.
    final class PanelOverrideView {
        var code: String
        var title: String
        var currencyText: String
        var bed: String
        var phone: String
        var batchSize: String
        var acuityText: String
        var statusLabel: String

        init(code: String, title: String, currencyText: String, bed: String, phone: String, batchSize: String, acuityText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.currencyText = currencyText
            self.bed = bed
            self.phone = phone
            self.batchSize = batchSize
            self.acuityText = acuityText
            self.statusLabel = statusLabel
        }
    }

    static func toPanelOverrideView(_ item: PanelOverride) -> PanelOverrideView {
        return PanelOverrideView(
            code: item.code,
            title: item.title,
            currencyText: Kit.Text.truncate(item.currency, limit: 120),
            bed: Kit.Text.truncate(item.bed, limit: 64),
            phone: Kit.Text.truncate(item.phone, limit: 40),
            batchSize: String(item.batchSize),
            acuityText: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelOverrideViews(_ items: [PanelOverride]) -> [PanelOverrideView] {
        var views: [PanelOverrideView] = []
        for item in items {
            views.append(toPanelOverrideView(item))
        }
        return views
    }

    static func sumPanelOverrideView(_ view: PanelOverrideView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedAcuity)
    }
}
