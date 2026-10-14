import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a default program baseline.
    final class DefaultProgramBaselineView {
        var codeText: String
        var label: String
        var graceDaysText: String
        var active: String
        var visible: String
        var statusLabel: String

        init(codeText: String, label: String, graceDaysText: String, active: String, visible: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.graceDaysText = graceDaysText
            self.active = active
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultProgramBaselineView(_ item: DefaultProgramBaseline) -> DefaultProgramBaselineView {
        return DefaultProgramBaselineView(
            codeText: item.code,
            label: item.label,
            graceDaysText: String(item.graceDays),
            active: "\(item.active)",
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultProgramBaselineViews(_ items: [DefaultProgramBaseline]) -> [DefaultProgramBaselineView] {
        var views: [DefaultProgramBaselineView] = []
        for item in items {
            views.append(toDefaultProgramBaselineView(item))
        }
        return views
    }

    static func sumDefaultProgramBaselineView(_ view: DefaultProgramBaselineView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedGraceDays)
    }
}
