import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance milestone.
    final class RemittanceMilestoneView {
        var codeText: String
        var titleText: String
        var country: String
        var ownerID: String
        var weight: String
        var graceDays: String
        var windowDays: String
        var dosageMgText: String
        var quantityText: String
        var copayText: String
        var statusLabel: String

        init(codeText: String, titleText: String, country: String, ownerID: String, weight: String, graceDays: String, windowDays: String, dosageMgText: String, quantityText: String, copayText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.country = country
            self.ownerID = ownerID
            self.weight = weight
            self.graceDays = graceDays
            self.windowDays = windowDays
            self.dosageMgText = dosageMgText
            self.quantityText = quantityText
            self.copayText = copayText
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceMilestoneView(_ item: RemittanceMilestone) -> RemittanceMilestoneView {
        return RemittanceMilestoneView(
            codeText: item.code,
            titleText: item.title,
            country: Kit.Text.truncate(item.country, limit: 80),
            ownerID: item.ownerID,
            weight: String(format: "%.2f", item.weight),
            graceDays: String(item.graceDays),
            windowDays: String(item.windowDays),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            quantityText: String(item.quantity),
            copayText: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceMilestoneViews(_ items: [RemittanceMilestone]) -> [RemittanceMilestoneView] {
        var views: [RemittanceMilestoneView] = []
        for item in items {
            views.append(toRemittanceMilestoneView(item))
        }
        return views
    }

    static func sumRemittanceMilestoneView(_ view: RemittanceMilestoneView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedWeight + Double(parsedGraceDays) + Double(parsedWindowDays)
    }
}
