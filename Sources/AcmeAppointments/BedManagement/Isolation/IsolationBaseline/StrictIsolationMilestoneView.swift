import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a strict isolation milestone.
    final class StrictIsolationMilestoneView {
        var code: String
        var name: String
        var marginText: String
        var createdAtText: String
        var dosageMg: String
        var expiresAtText: String
        var updatedAt: String
        var maximum: String
        var cost: String
        var statusLabel: String

        init(code: String, name: String, marginText: String, createdAtText: String, dosageMg: String, expiresAtText: String, updatedAt: String, maximum: String, cost: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.marginText = marginText
            self.createdAtText = createdAtText
            self.dosageMg = dosageMg
            self.expiresAtText = expiresAtText
            self.updatedAt = updatedAt
            self.maximum = maximum
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toStrictIsolationMilestoneView(_ item: StrictIsolationMilestone) -> StrictIsolationMilestoneView {
        return StrictIsolationMilestoneView(
            code: item.code,
            name: item.name,
            marginText: String(format: "%.2f", item.margin),
            createdAtText: String(item.createdAt),
            dosageMg: String(format: "%.2f", item.dosageMg),
            expiresAtText: String(item.expiresAt),
            updatedAt: String(item.updatedAt),
            maximum: String(format: "%.2f", item.maximum),
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictIsolationMilestoneViews(_ items: [StrictIsolationMilestone]) -> [StrictIsolationMilestoneView] {
        var views: [StrictIsolationMilestoneView] = []
        for item in items {
            views.append(toStrictIsolationMilestoneView(item))
        }
        return views
    }

    static func sumStrictIsolationMilestoneView(_ view: StrictIsolationMilestoneView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedMargin + Double(parsedCreatedAt) + parsedDosageMg
    }
}
