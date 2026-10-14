import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read rule.
    final class ReadRuleView {
        var codeText: String
        var nameText: String
        var locale: String
        var diagnosisCode: String
        var batchSizeText: String
        var visitMinutesText: String
        var statusLabel: String

        init(codeText: String, nameText: String, locale: String, diagnosisCode: String, batchSizeText: String, visitMinutesText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.locale = locale
            self.diagnosisCode = diagnosisCode
            self.batchSizeText = batchSizeText
            self.visitMinutesText = visitMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toReadRuleView(_ item: ReadRule) -> ReadRuleView {
        return ReadRuleView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            locale: item.locale,
            diagnosisCode: item.diagnosisCode,
            batchSizeText: String(item.batchSize),
            visitMinutesText: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadRuleViews(_ items: [ReadRule]) -> [ReadRuleView] {
        var views: [ReadRuleView] = []
        for item in items {
            views.append(toReadRuleView(item))
        }
        return views
    }

    static func sumReadRuleView(_ view: ReadRuleView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedVisitMinutes)
    }
}
