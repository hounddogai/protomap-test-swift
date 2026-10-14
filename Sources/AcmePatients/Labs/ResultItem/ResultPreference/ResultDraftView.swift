import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result draft.
    final class ResultDraftView {
        var code: String
        var name: String
        var procedureCode: String
        var checksum: String
        var notes: String
        var weight: String
        var approvedText: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, name: String, procedureCode: String, checksum: String, notes: String, weight: String, approvedText: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.checksum = checksum
            self.notes = notes
            self.weight = weight
            self.approvedText = approvedText
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toResultDraftView(_ item: ResultDraft) -> ResultDraftView {
        return ResultDraftView(
            code: item.code,
            name: item.name,
            procedureCode: item.procedureCode,
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            notes: item.notes,
            weight: String(format: "%.2f", item.weight),
            approvedText: "\(item.approved)",
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultDraftViews(_ items: [ResultDraft]) -> [ResultDraftView] {
        var views: [ResultDraftView] = []
        for item in items {
            views.append(toResultDraftView(item))
        }
        return views
    }

    static func sumResultDraftView(_ view: ResultDraftView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedWeight + Double(parsedDurationMinutes)
    }
}
