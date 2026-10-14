import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a capped revocation bundle.
    final class CappedRevocationBundleView {
        var codeText: String
        var name: String
        var ceiling: String
        var rate: String
        var maximumText: String
        var weight: String
        var acuity: String
        var ratioText: String
        var statusLabel: String

        init(codeText: String, name: String, ceiling: String, rate: String, maximumText: String, weight: String, acuity: String, ratioText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.ceiling = ceiling
            self.rate = rate
            self.maximumText = maximumText
            self.weight = weight
            self.acuity = acuity
            self.ratioText = ratioText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedRevocationBundleView(_ item: CappedRevocationBundle) -> CappedRevocationBundleView {
        return CappedRevocationBundleView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            ceiling: String(format: "%.2f", item.ceiling),
            rate: String(format: "%.2f", item.rate),
            maximumText: String(format: "%.2f", item.maximum),
            weight: String(format: "%.2f", item.weight),
            acuity: String(item.acuity),
            ratioText: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedRevocationBundleViews(_ items: [CappedRevocationBundle]) -> [CappedRevocationBundleView] {
        var views: [CappedRevocationBundleView] = []
        for item in items {
            views.append(toCappedRevocationBundleView(item))
        }
        return views
    }

    static func sumCappedRevocationBundleView(_ view: CappedRevocationBundleView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedCeiling + parsedRate + parsedMaximum
    }
}
