import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert target.
    final class AlertTargetView {
        var code: String
        var label: String
        var diagnosisCode: String
        var discount: String
        var capacity: String
        var ratio: String
        var cost: String
        var visible: String
        var clinicianID: String
        var margin: String
        var unitText: String
        var statusLabel: String

        init(code: String, label: String, diagnosisCode: String, discount: String, capacity: String, ratio: String, cost: String, visible: String, clinicianID: String, margin: String, unitText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.discount = discount
            self.capacity = capacity
            self.ratio = ratio
            self.cost = cost
            self.visible = visible
            self.clinicianID = clinicianID
            self.margin = margin
            self.unitText = unitText
            self.statusLabel = statusLabel
        }
    }

    static func toAlertTargetView(_ item: AlertTarget) -> AlertTargetView {
        return AlertTargetView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            discount: String(format: "%.2f", item.discount),
            capacity: String(item.capacity),
            ratio: String(format: "%.2f", item.ratio),
            cost: String(format: "%.2f", item.cost),
            visible: "\(item.visible)",
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 120),
            margin: String(format: "%.2f", item.margin),
            unitText: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertTargetViews(_ items: [AlertTarget]) -> [AlertTargetView] {
        var views: [AlertTargetView] = []
        for item in items {
            views.append(toAlertTargetView(item))
        }
        return views
    }

    static func sumAlertTargetView(_ view: AlertTargetView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedDiscount + Double(parsedCapacity) + parsedRatio
    }
}
