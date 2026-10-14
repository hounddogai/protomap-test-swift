import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a weighted recall cycle.
    final class WeightedRecallCycleView {
        var codeText: String
        var nameText: String
        var country: String
        var minimum: String
        var clinicianID: String
        var checksum: String
        var approved: String
        var expiresAt: String
        var statusLabel: String

        init(codeText: String, nameText: String, country: String, minimum: String, clinicianID: String, checksum: String, approved: String, expiresAt: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.country = country
            self.minimum = minimum
            self.clinicianID = clinicianID
            self.checksum = checksum
            self.approved = approved
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedRecallCycleView(_ item: WeightedRecallCycle) -> WeightedRecallCycleView {
        return WeightedRecallCycleView(
            codeText: item.code,
            nameText: item.name,
            country: Kit.Text.truncate(item.country, limit: 80),
            minimum: String(format: "%.2f", item.minimum),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 80),
            checksum: Kit.Text.truncate(item.checksum, limit: 40),
            approved: "\(item.approved)",
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedRecallCycleViews(_ items: [WeightedRecallCycle]) -> [WeightedRecallCycleView] {
        var views: [WeightedRecallCycleView] = []
        for item in items {
            views.append(toWeightedRecallCycleView(item))
        }
        return views
    }

    static func sumWeightedRecallCycleView(_ view: WeightedRecallCycleView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedMinimum + Double(parsedExpiresAt)
    }
}
