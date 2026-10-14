import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a lenient task window.
    final class LenientTaskWindowView {
        var code: String
        var title: String
        var windowDaysText: String
        var durationMinutesText: String
        var quantity: String
        var procedureCode: String
        var notesText: String
        var statusLabel: String

        init(code: String, title: String, windowDaysText: String, durationMinutesText: String, quantity: String, procedureCode: String, notesText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.windowDaysText = windowDaysText
            self.durationMinutesText = durationMinutesText
            self.quantity = quantity
            self.procedureCode = procedureCode
            self.notesText = notesText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientTaskWindowView(_ item: LenientTaskWindow) -> LenientTaskWindowView {
        return LenientTaskWindowView(
            code: item.code,
            title: item.title,
            windowDaysText: String(item.windowDays),
            durationMinutesText: String(item.durationMinutes),
            quantity: String(item.quantity),
            procedureCode: item.procedureCode,
            notesText: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientTaskWindowViews(_ items: [LenientTaskWindow]) -> [LenientTaskWindowView] {
        var views: [LenientTaskWindowView] = []
        for item in items {
            views.append(toLenientTaskWindowView(item))
        }
        return views
    }

    static func sumLenientTaskWindowView(_ view: LenientTaskWindowView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedDurationMinutes) + Double(parsedQuantity)
    }
}
