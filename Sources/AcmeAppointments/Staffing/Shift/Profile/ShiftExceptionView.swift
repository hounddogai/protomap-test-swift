import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a shift exception.
    final class ShiftExceptionView {
        var codeText: String
        var titleText: String
        var summary: String
        var dosageMg: String
        var sourceText: String
        var minimum: String
        var notes: String
        var phone: String
        var name: String
        var copayText: String
        var statusLabel: String

        init(codeText: String, titleText: String, summary: String, dosageMg: String, sourceText: String, minimum: String, notes: String, phone: String, name: String, copayText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.summary = summary
            self.dosageMg = dosageMg
            self.sourceText = sourceText
            self.minimum = minimum
            self.notes = notes
            self.phone = phone
            self.name = name
            self.copayText = copayText
            self.statusLabel = statusLabel
        }
    }

    static func toShiftExceptionView(_ item: ShiftException) -> ShiftExceptionView {
        return ShiftExceptionView(
            codeText: item.code,
            titleText: item.title,
            summary: Kit.Text.truncate(item.summary, limit: 80),
            dosageMg: String(format: "%.2f", item.dosageMg),
            sourceText: Kit.Text.truncate(item.source, limit: 40),
            minimum: String(format: "%.2f", item.minimum),
            notes: item.notes,
            phone: Kit.Text.truncate(item.phone, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 64),
            copayText: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toShiftExceptionViews(_ items: [ShiftException]) -> [ShiftExceptionView] {
        var views: [ShiftExceptionView] = []
        for item in items {
            views.append(toShiftExceptionView(item))
        }
        return views
    }

    static func sumShiftExceptionView(_ view: ShiftExceptionView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedDosageMg + parsedMinimum + parsedCopay
    }
}
