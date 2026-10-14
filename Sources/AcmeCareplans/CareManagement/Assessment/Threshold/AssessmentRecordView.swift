import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment record.
    final class AssessmentRecordView {
        var code: String
        var titleText: String
        var visible: String
        var dosageMg: String
        var windowDays: String
        var rate: String
        var archivedText: String
        var amountText: String
        var acuity: String
        var description: String
        var statusLabel: String

        init(code: String, titleText: String, visible: String, dosageMg: String, windowDays: String, rate: String, archivedText: String, amountText: String, acuity: String, description: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.visible = visible
            self.dosageMg = dosageMg
            self.windowDays = windowDays
            self.rate = rate
            self.archivedText = archivedText
            self.amountText = amountText
            self.acuity = acuity
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentRecordView(_ item: AssessmentRecord) -> AssessmentRecordView {
        return AssessmentRecordView(
            code: item.code,
            titleText: item.title,
            visible: "\(item.visible)",
            dosageMg: String(format: "%.2f", item.dosageMg),
            windowDays: String(item.windowDays),
            rate: String(format: "%.2f", item.rate),
            archivedText: "\(item.archived)",
            amountText: String(format: "%.2f", item.amount),
            acuity: String(item.acuity),
            description: Kit.Text.truncate(item.description, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentRecordViews(_ items: [AssessmentRecord]) -> [AssessmentRecordView] {
        var views: [AssessmentRecordView] = []
        for item in items {
            views.append(toAssessmentRecordView(item))
        }
        return views
    }

    static func sumAssessmentRecordView(_ view: AssessmentRecordView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedDosageMg + Double(parsedWindowDays) + parsedRate
    }
}
