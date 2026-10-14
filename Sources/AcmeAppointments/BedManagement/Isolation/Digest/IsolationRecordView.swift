import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation record.
    final class IsolationRecordView {
        var code: String
        var label: String
        var weight: String
        var segment: String
        var procedureCode: String
        var attempts: String
        var allergy: String
        var category: String
        var minimumText: String
        var statusLabel: String

        init(code: String, label: String, weight: String, segment: String, procedureCode: String, attempts: String, allergy: String, category: String, minimumText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.weight = weight
            self.segment = segment
            self.procedureCode = procedureCode
            self.attempts = attempts
            self.allergy = allergy
            self.category = category
            self.minimumText = minimumText
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationRecordView(_ item: IsolationRecord) -> IsolationRecordView {
        return IsolationRecordView(
            code: item.code,
            label: item.label,
            weight: String(format: "%.2f", item.weight),
            segment: item.segment,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            attempts: String(item.attempts),
            allergy: item.allergy,
            category: item.category,
            minimumText: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationRecordViews(_ items: [IsolationRecord]) -> [IsolationRecordView] {
        var views: [IsolationRecordView] = []
        for item in items {
            views.append(toIsolationRecordView(item))
        }
        return views
    }

    static func sumIsolationRecordView(_ view: IsolationRecordView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedWeight + Double(parsedAttempts) + parsedMinimum
    }
}
