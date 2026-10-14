import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime checkpoint.
    final class OvertimeCheckpointView {
        var code: String
        var label: String
        var updatedAt: String
        var startsAt: String
        var ceiling: String
        var payer: String
        var bedText: String
        var statusLabel: String

        init(code: String, label: String, updatedAt: String, startsAt: String, ceiling: String, payer: String, bedText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.startsAt = startsAt
            self.ceiling = ceiling
            self.payer = payer
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeCheckpointView(_ item: OvertimeCheckpoint) -> OvertimeCheckpointView {
        return OvertimeCheckpointView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            updatedAt: String(item.updatedAt),
            startsAt: String(item.startsAt),
            ceiling: String(format: "%.2f", item.ceiling),
            payer: Kit.Text.truncate(item.payer, limit: 40),
            bedText: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeCheckpointViews(_ items: [OvertimeCheckpoint]) -> [OvertimeCheckpointView] {
        var views: [OvertimeCheckpointView] = []
        for item in items {
            views.append(toOvertimeCheckpointView(item))
        }
        return views
    }

    static func sumOvertimeCheckpointView(_ view: OvertimeCheckpointView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedStartsAt) + parsedCeiling
    }
}
