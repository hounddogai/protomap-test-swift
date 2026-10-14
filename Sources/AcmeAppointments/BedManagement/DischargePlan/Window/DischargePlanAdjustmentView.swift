import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan adjustment.
    final class DischargePlanAdjustmentView {
        var codeText: String
        var titleText: String
        var pinnedText: String
        var phone: String
        var diagnosisCode: String
        var limit: String
        var createdAt: String
        var statusLabel: String

        init(codeText: String, titleText: String, pinnedText: String, phone: String, diagnosisCode: String, limit: String, createdAt: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.pinnedText = pinnedText
            self.phone = phone
            self.diagnosisCode = diagnosisCode
            self.limit = limit
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanAdjustmentView(_ item: DischargePlanAdjustment) -> DischargePlanAdjustmentView {
        return DischargePlanAdjustmentView(
            codeText: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 40),
            pinnedText: "\(item.pinned)",
            phone: item.phone,
            diagnosisCode: item.diagnosisCode,
            limit: String(item.limit),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanAdjustmentViews(_ items: [DischargePlanAdjustment]) -> [DischargePlanAdjustmentView] {
        var views: [DischargePlanAdjustmentView] = []
        for item in items {
            views.append(toDischargePlanAdjustmentView(item))
        }
        return views
    }

    static func sumDischargePlanAdjustmentView(_ view: DischargePlanAdjustmentView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedLimit) + Double(parsedCreatedAt)
    }
}
