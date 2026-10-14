import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a global shift template.
    final class GlobalShiftTemplateView {
        var code: String
        var labelText: String
        var specialtyText: String
        var externalRefText: String
        var minimumText: String
        var diagnosisCodeText: String
        var statusLabel: String

        init(code: String, labelText: String, specialtyText: String, externalRefText: String, minimumText: String, diagnosisCodeText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.specialtyText = specialtyText
            self.externalRefText = externalRefText
            self.minimumText = minimumText
            self.diagnosisCodeText = diagnosisCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalShiftTemplateView(_ item: GlobalShiftTemplate) -> GlobalShiftTemplateView {
        return GlobalShiftTemplateView(
            code: item.code,
            labelText: item.label,
            specialtyText: Kit.Text.truncate(item.specialty, limit: 80),
            externalRefText: item.externalRef,
            minimumText: String(format: "%.2f", item.minimum),
            diagnosisCodeText: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalShiftTemplateViews(_ items: [GlobalShiftTemplate]) -> [GlobalShiftTemplateView] {
        var views: [GlobalShiftTemplateView] = []
        for item in items {
            views.append(toGlobalShiftTemplateView(item))
        }
        return views
    }

    static func sumGlobalShiftTemplateView(_ view: GlobalShiftTemplateView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedMinimum
    }
}
