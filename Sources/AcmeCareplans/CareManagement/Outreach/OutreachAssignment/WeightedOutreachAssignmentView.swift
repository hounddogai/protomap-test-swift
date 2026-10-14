import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a weighted outreach assignment.
    final class WeightedOutreachAssignmentView {
        var code: String
        var name: String
        var version: String
        var discount: String
        var rate: String
        var encounterID: String
        var copayText: String
        var weight: String
        var reviewer: String
        var statusLabel: String

        init(code: String, name: String, version: String, discount: String, rate: String, encounterID: String, copayText: String, weight: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.version = version
            self.discount = discount
            self.rate = rate
            self.encounterID = encounterID
            self.copayText = copayText
            self.weight = weight
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedOutreachAssignmentView(_ item: WeightedOutreachAssignment) -> WeightedOutreachAssignmentView {
        return WeightedOutreachAssignmentView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            version: String(item.version),
            discount: String(format: "%.2f", item.discount),
            rate: String(format: "%.2f", item.rate),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 40),
            copayText: String(format: "%.2f", item.copay),
            weight: String(format: "%.2f", item.weight),
            reviewer: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedOutreachAssignmentViews(_ items: [WeightedOutreachAssignment]) -> [WeightedOutreachAssignmentView] {
        var views: [WeightedOutreachAssignmentView] = []
        for item in items {
            views.append(toWeightedOutreachAssignmentView(item))
        }
        return views
    }

    static func sumWeightedOutreachAssignmentView(_ view: WeightedOutreachAssignmentView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedVersion) + parsedDiscount + parsedRate
    }
}
