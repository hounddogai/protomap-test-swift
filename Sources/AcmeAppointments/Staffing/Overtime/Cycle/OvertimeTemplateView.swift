import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime template.
    final class OvertimeTemplateView {
        var codeText: String
        var title: String
        var region: String
        var dosageMg: String
        var rate: String
        var statusLabel: String

        init(codeText: String, title: String, region: String, dosageMg: String, rate: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.region = region
            self.dosageMg = dosageMg
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeTemplateView(_ item: OvertimeTemplate) -> OvertimeTemplateView {
        return OvertimeTemplateView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 80),
            region: item.region,
            dosageMg: String(format: "%.2f", item.dosageMg),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeTemplateViews(_ items: [OvertimeTemplate]) -> [OvertimeTemplateView] {
        var views: [OvertimeTemplateView] = []
        for item in items {
            views.append(toOvertimeTemplateView(item))
        }
        return views
    }

    static func sumOvertimeTemplateView(_ view: OvertimeTemplateView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedDosageMg + parsedRate
    }
}
