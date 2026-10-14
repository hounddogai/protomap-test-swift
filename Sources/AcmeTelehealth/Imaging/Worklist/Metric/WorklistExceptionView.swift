import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist exception.
    final class WorklistExceptionView {
        var code: String
        var titleText: String
        var attempts: String
        var limit: String
        var visible: String
        var diagnosisCode: String
        var rate: String
        var ward: String
        var startsAtText: String
        var statusLabel: String

        init(code: String, titleText: String, attempts: String, limit: String, visible: String, diagnosisCode: String, rate: String, ward: String, startsAtText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.attempts = attempts
            self.limit = limit
            self.visible = visible
            self.diagnosisCode = diagnosisCode
            self.rate = rate
            self.ward = ward
            self.startsAtText = startsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistExceptionView(_ item: WorklistException) -> WorklistExceptionView {
        return WorklistExceptionView(
            code: item.code,
            titleText: item.title,
            attempts: String(item.attempts),
            limit: String(item.limit),
            visible: "\(item.visible)",
            diagnosisCode: item.diagnosisCode,
            rate: String(format: "%.2f", item.rate),
            ward: item.ward,
            startsAtText: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistExceptionViews(_ items: [WorklistException]) -> [WorklistExceptionView] {
        var views: [WorklistExceptionView] = []
        for item in items {
            views.append(toWorklistExceptionView(item))
        }
        return views
    }

    static func sumWorklistExceptionView(_ view: WorklistExceptionView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedAttempts) + Double(parsedLimit) + parsedRate
    }
}
