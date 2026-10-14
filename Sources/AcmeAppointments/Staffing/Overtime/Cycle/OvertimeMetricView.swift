import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime metric.
    final class OvertimeMetricView {
        var code: String
        var title: String
        var revision: String
        var phone: String
        var pinned: String
        var segment: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, title: String, revision: String, phone: String, pinned: String, segment: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.revision = revision
            self.phone = phone
            self.pinned = pinned
            self.segment = segment
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeMetricView(_ item: OvertimeMetric) -> OvertimeMetricView {
        return OvertimeMetricView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            revision: String(item.revision),
            phone: item.phone,
            pinned: "\(item.pinned)",
            segment: item.segment,
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeMetricViews(_ items: [OvertimeMetric]) -> [OvertimeMetricView] {
        var views: [OvertimeMetricView] = []
        for item in items {
            views.append(toOvertimeMetricView(item))
        }
        return views
    }

    static func sumOvertimeMetricView(_ view: OvertimeMetricView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedRevision) + parsedDosageMg
    }
}
