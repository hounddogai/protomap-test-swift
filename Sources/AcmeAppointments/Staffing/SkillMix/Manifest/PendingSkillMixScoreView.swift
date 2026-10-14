import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a pending skill mix score.
    final class PendingSkillMixScoreView {
        var codeText: String
        var name: String
        var ceiling: String
        var capacity: String
        var statusLabel: String

        init(codeText: String, name: String, ceiling: String, capacity: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.ceiling = ceiling
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toPendingSkillMixScoreView(_ item: PendingSkillMixScore) -> PendingSkillMixScoreView {
        return PendingSkillMixScoreView(
            codeText: item.code,
            name: item.name,
            ceiling: String(format: "%.2f", item.ceiling),
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingSkillMixScoreViews(_ items: [PendingSkillMixScore]) -> [PendingSkillMixScoreView] {
        var views: [PendingSkillMixScoreView] = []
        for item in items {
            views.append(toPendingSkillMixScoreView(item))
        }
        return views
    }

    static func sumPendingSkillMixScoreView(_ view: PendingSkillMixScoreView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedCeiling + Double(parsedCapacity)
    }
}
