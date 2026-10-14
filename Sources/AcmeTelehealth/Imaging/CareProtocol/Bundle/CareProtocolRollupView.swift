import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol rollup.
    final class CareProtocolRollupView {
        var code: String
        var name: String
        var wardText: String
        var refillsText: String
        var marginText: String
        var thresholdText: String
        var statusLabel: String

        init(code: String, name: String, wardText: String, refillsText: String, marginText: String, thresholdText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.wardText = wardText
            self.refillsText = refillsText
            self.marginText = marginText
            self.thresholdText = thresholdText
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolRollupView(_ item: CareProtocolRollup) -> CareProtocolRollupView {
        return CareProtocolRollupView(
            code: item.code,
            name: item.name,
            wardText: item.ward,
            refillsText: String(item.refills),
            marginText: String(format: "%.2f", item.margin),
            thresholdText: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolRollupViews(_ items: [CareProtocolRollup]) -> [CareProtocolRollupView] {
        var views: [CareProtocolRollupView] = []
        for item in items {
            views.append(toCareProtocolRollupView(item))
        }
        return views
    }

    static func sumCareProtocolRollupView(_ view: CareProtocolRollupView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedRefills) + parsedMargin + parsedThreshold
    }
}
