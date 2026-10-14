import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a handoff adjustment.
    final class HandoffAdjustmentView {
        var code: String
        var titleText: String
        var ward: String
        var summary: String
        var timezone: String
        var diagnosisCodeText: String
        var quantity: String
        var statusLabel: String

        init(code: String, titleText: String, ward: String, summary: String, timezone: String, diagnosisCodeText: String, quantity: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.ward = ward
            self.summary = summary
            self.timezone = timezone
            self.diagnosisCodeText = diagnosisCodeText
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toHandoffAdjustmentView(_ item: HandoffAdjustment) -> HandoffAdjustmentView {
        return HandoffAdjustmentView(
            code: item.code,
            titleText: item.title,
            ward: item.ward,
            summary: Kit.Text.truncate(item.summary, limit: 40),
            timezone: Kit.Text.truncate(item.timezone, limit: 40),
            diagnosisCodeText: item.diagnosisCode,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toHandoffAdjustmentViews(_ items: [HandoffAdjustment]) -> [HandoffAdjustmentView] {
        var views: [HandoffAdjustmentView] = []
        for item in items {
            views.append(toHandoffAdjustmentView(item))
        }
        return views
    }

    static func sumHandoffAdjustmentView(_ view: HandoffAdjustmentView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
