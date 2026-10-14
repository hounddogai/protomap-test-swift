import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier baseline.
    final class CourierBaselineView {
        var code: String
        var nameText: String
        var retriesText: String
        var copay: String
        var visible: String
        var thresholdText: String
        var acuity: String
        var statusLabel: String

        init(code: String, nameText: String, retriesText: String, copay: String, visible: String, thresholdText: String, acuity: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.retriesText = retriesText
            self.copay = copay
            self.visible = visible
            self.thresholdText = thresholdText
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toCourierBaselineView(_ item: CourierBaseline) -> CourierBaselineView {
        return CourierBaselineView(
            code: item.code,
            nameText: item.name,
            retriesText: String(item.retries),
            copay: String(format: "%.2f", item.copay),
            visible: "\(item.visible)",
            thresholdText: String(format: "%.2f", item.threshold),
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierBaselineViews(_ items: [CourierBaseline]) -> [CourierBaselineView] {
        var views: [CourierBaselineView] = []
        for item in items {
            views.append(toCourierBaselineView(item))
        }
        return views
    }

    static func sumCourierBaselineView(_ view: CourierBaselineView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedRetries) + parsedCopay + parsedThreshold
    }
}
