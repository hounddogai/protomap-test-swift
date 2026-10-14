import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study baseline.
    final class StudyBaselineView {
        var code: String
        var label: String
        var windowDays: String
        var notes: String
        var quantityText: String
        var rate: String
        var ward: String
        var sourceText: String
        var dosageMgText: String
        var statusLabel: String

        init(code: String, label: String, windowDays: String, notes: String, quantityText: String, rate: String, ward: String, sourceText: String, dosageMgText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.notes = notes
            self.quantityText = quantityText
            self.rate = rate
            self.ward = ward
            self.sourceText = sourceText
            self.dosageMgText = dosageMgText
            self.statusLabel = statusLabel
        }
    }

    static func toStudyBaselineView(_ item: StudyBaseline) -> StudyBaselineView {
        return StudyBaselineView(
            code: item.code,
            label: item.label,
            windowDays: String(item.windowDays),
            notes: item.notes,
            quantityText: String(item.quantity),
            rate: String(format: "%.2f", item.rate),
            ward: Kit.Text.truncate(item.ward, limit: 80),
            sourceText: item.source,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyBaselineViews(_ items: [StudyBaseline]) -> [StudyBaselineView] {
        var views: [StudyBaselineView] = []
        for item in items {
            views.append(toStudyBaselineView(item))
        }
        return views
    }

    static func sumStudyBaselineView(_ view: StudyBaselineView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedQuantity) + parsedRate
    }
}
