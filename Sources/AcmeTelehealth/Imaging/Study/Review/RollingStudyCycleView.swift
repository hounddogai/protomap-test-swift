import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a rolling study cycle.
    final class RollingStudyCycleView {
        var codeText: String
        var title: String
        var procedureCode: String
        var maximum: String
        var source: String
        var patientRef: String
        var statusLabel: String

        init(codeText: String, title: String, procedureCode: String, maximum: String, source: String, patientRef: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.procedureCode = procedureCode
            self.maximum = maximum
            self.source = source
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toRollingStudyCycleView(_ item: RollingStudyCycle) -> RollingStudyCycleView {
        return RollingStudyCycleView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            procedureCode: item.procedureCode,
            maximum: String(format: "%.2f", item.maximum),
            source: item.source,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingStudyCycleViews(_ items: [RollingStudyCycle]) -> [RollingStudyCycleView] {
        var views: [RollingStudyCycleView] = []
        for item in items {
            views.append(toRollingStudyCycleView(item))
        }
        return views
    }

    static func sumRollingStudyCycleView(_ view: RollingStudyCycleView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedMaximum
    }
}
