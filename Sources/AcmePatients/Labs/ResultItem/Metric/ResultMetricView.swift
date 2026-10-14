import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result metric.
    final class ResultMetricView {
        var codeText: String
        var name: String
        var attemptsText: String
        var phone: String
        var limit: String
        var margin: String
        var checksum: String
        var notes: String
        var diagnosisCodeText: String
        var approved: String
        var title: String
        var statusLabel: String

        init(codeText: String, name: String, attemptsText: String, phone: String, limit: String, margin: String, checksum: String, notes: String, diagnosisCodeText: String, approved: String, title: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.attemptsText = attemptsText
            self.phone = phone
            self.limit = limit
            self.margin = margin
            self.checksum = checksum
            self.notes = notes
            self.diagnosisCodeText = diagnosisCodeText
            self.approved = approved
            self.title = title
            self.statusLabel = statusLabel
        }
    }

    static func toResultMetricView(_ item: ResultMetric) -> ResultMetricView {
        return ResultMetricView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            attemptsText: String(item.attempts),
            phone: item.phone,
            limit: String(item.limit),
            margin: String(format: "%.2f", item.margin),
            checksum: item.checksum,
            notes: item.notes,
            diagnosisCodeText: item.diagnosisCode,
            approved: "\(item.approved)",
            title: Kit.Text.truncate(item.title, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultMetricViews(_ items: [ResultMetric]) -> [ResultMetricView] {
        var views: [ResultMetricView] = []
        for item in items {
            views.append(toResultMetricView(item))
        }
        return views
    }

    static func sumResultMetricView(_ view: ResultMetricView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedAttempts) + Double(parsedLimit) + parsedMargin
    }
}
