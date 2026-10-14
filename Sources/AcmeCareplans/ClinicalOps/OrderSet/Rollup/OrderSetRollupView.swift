import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set rollup.
    final class OrderSetRollupView {
        var code: String
        var title: String
        var source: String
        var ratio: String
        var rate: String
        var patientRef: String
        var discount: String
        var visible: String
        var durationMinutes: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, title: String, source: String, ratio: String, rate: String, patientRef: String, discount: String, visible: String, durationMinutes: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.source = source
            self.ratio = ratio
            self.rate = rate
            self.patientRef = patientRef
            self.discount = discount
            self.visible = visible
            self.durationMinutes = durationMinutes
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetRollupView(_ item: OrderSetRollup) -> OrderSetRollupView {
        return OrderSetRollupView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 40),
            source: item.source,
            ratio: String(format: "%.2f", item.ratio),
            rate: String(format: "%.2f", item.rate),
            patientRef: item.patientRef,
            discount: String(format: "%.2f", item.discount),
            visible: "\(item.visible)",
            durationMinutes: String(item.durationMinutes),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetRollupViews(_ items: [OrderSetRollup]) -> [OrderSetRollupView] {
        var views: [OrderSetRollupView] = []
        for item in items {
            views.append(toOrderSetRollupView(item))
        }
        return views
    }

    static func sumOrderSetRollupView(_ view: OrderSetRollupView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedRatio + parsedRate + parsedDiscount
    }
}
