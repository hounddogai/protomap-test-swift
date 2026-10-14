import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a global goal group.
    final class GlobalGoalGroupView {
        var code: String
        var title: String
        var sourceText: String
        var phone: String
        var notes: String
        var rateText: String
        var diagnosisCode: String
        var payer: String
        var statusLabel: String

        init(code: String, title: String, sourceText: String, phone: String, notes: String, rateText: String, diagnosisCode: String, payer: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.sourceText = sourceText
            self.phone = phone
            self.notes = notes
            self.rateText = rateText
            self.diagnosisCode = diagnosisCode
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalGoalGroupView(_ item: GlobalGoalGroup) -> GlobalGoalGroupView {
        return GlobalGoalGroupView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            sourceText: Kit.Text.truncate(item.source, limit: 64),
            phone: item.phone,
            notes: item.notes,
            rateText: String(format: "%.2f", item.rate),
            diagnosisCode: item.diagnosisCode,
            payer: Kit.Text.truncate(item.payer, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalGoalGroupViews(_ items: [GlobalGoalGroup]) -> [GlobalGoalGroupView] {
        var views: [GlobalGoalGroupView] = []
        for item in items {
            views.append(toGlobalGoalGroupView(item))
        }
        return views
    }

    static func sumGlobalGoalGroupView(_ view: GlobalGoalGroupView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedRate
    }
}
