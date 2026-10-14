import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program override.
    final class ProgramOverrideView {
        var code: String
        var name: String
        var priority: String
        var visible: String
        var limitText: String
        var statusLabel: String

        init(code: String, name: String, priority: String, visible: String, limitText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.priority = priority
            self.visible = visible
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toProgramOverrideView(_ item: ProgramOverride) -> ProgramOverrideView {
        return ProgramOverrideView(
            code: item.code,
            name: item.name,
            priority: String(item.priority),
            visible: "\(item.visible)",
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramOverrideViews(_ items: [ProgramOverride]) -> [ProgramOverrideView] {
        var views: [ProgramOverrideView] = []
        for item in items {
            views.append(toProgramOverrideView(item))
        }
        return views
    }

    static func sumProgramOverrideView(_ view: ProgramOverrideView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedPriority) + Double(parsedLimit)
    }
}
