import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a regional overtime window.
    final class RegionalOvertimeWindowView {
        var code: String
        var name: String
        var active: String
        var durationMinutes: String
        var batchSize: String
        var ward: String
        var score: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, name: String, active: String, durationMinutes: String, batchSize: String, ward: String, score: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.active = active
            self.durationMinutes = durationMinutes
            self.batchSize = batchSize
            self.ward = ward
            self.score = score
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalOvertimeWindowView(_ item: RegionalOvertimeWindow) -> RegionalOvertimeWindowView {
        return RegionalOvertimeWindowView(
            code: item.code,
            name: item.name,
            active: "\(item.active)",
            durationMinutes: String(item.durationMinutes),
            batchSize: String(item.batchSize),
            ward: Kit.Text.truncate(item.ward, limit: 40),
            score: String(format: "%.2f", item.score),
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalOvertimeWindowViews(_ items: [RegionalOvertimeWindow]) -> [RegionalOvertimeWindowView] {
        var views: [RegionalOvertimeWindowView] = []
        for item in items {
            views.append(toRegionalOvertimeWindowView(item))
        }
        return views
    }

    static func sumRegionalOvertimeWindowView(_ view: RegionalOvertimeWindowView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedBatchSize) + parsedScore
    }
}
