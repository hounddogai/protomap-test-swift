import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a seasonal program group.
    final class SeasonalProgramGroupView {
        var code: String
        var nameText: String
        var archivedText: String
        var amount: String
        var phone: String
        var graceDays: String
        var threshold: String
        var expiresAt: String
        var label: String
        var statusLabel: String

        init(code: String, nameText: String, archivedText: String, amount: String, phone: String, graceDays: String, threshold: String, expiresAt: String, label: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.archivedText = archivedText
            self.amount = amount
            self.phone = phone
            self.graceDays = graceDays
            self.threshold = threshold
            self.expiresAt = expiresAt
            self.label = label
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalProgramGroupView(_ item: SeasonalProgramGroup) -> SeasonalProgramGroupView {
        return SeasonalProgramGroupView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 64),
            archivedText: "\(item.archived)",
            amount: String(format: "%.2f", item.amount),
            phone: Kit.Text.truncate(item.phone, limit: 64),
            graceDays: String(item.graceDays),
            threshold: String(format: "%.2f", item.threshold),
            expiresAt: String(item.expiresAt),
            label: Kit.Text.truncate(item.label, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalProgramGroupViews(_ items: [SeasonalProgramGroup]) -> [SeasonalProgramGroupView] {
        var views: [SeasonalProgramGroupView] = []
        for item in items {
            views.append(toSeasonalProgramGroupView(item))
        }
        return views
    }

    static func sumSeasonalProgramGroupView(_ view: SeasonalProgramGroupView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedAmount + Double(parsedGraceDays) + parsedThreshold
    }
}
