import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime record.
    final class OvertimeRecordView {
        var code: String
        var name: String
        var endsAtText: String
        var locale: String
        var notesText: String
        var procedureCode: String
        var label: String
        var statusLabel: String

        init(code: String, name: String, endsAtText: String, locale: String, notesText: String, procedureCode: String, label: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.endsAtText = endsAtText
            self.locale = locale
            self.notesText = notesText
            self.procedureCode = procedureCode
            self.label = label
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeRecordView(_ item: OvertimeRecord) -> OvertimeRecordView {
        return OvertimeRecordView(
            code: item.code,
            name: item.name,
            endsAtText: String(item.endsAt),
            locale: item.locale,
            notesText: item.notes,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeRecordViews(_ items: [OvertimeRecord]) -> [OvertimeRecordView] {
        var views: [OvertimeRecordView] = []
        for item in items {
            views.append(toOvertimeRecordView(item))
        }
        return views
    }

    static func sumOvertimeRecordView(_ view: OvertimeRecordView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedEndsAt)
    }
}
