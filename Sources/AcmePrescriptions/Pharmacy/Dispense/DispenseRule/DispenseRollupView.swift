import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense rollup.
    final class DispenseRollupView {
        var code: String
        var name: String
        var approved: String
        var region: String
        var copayText: String
        var version: String
        var startsAt: String
        var categoryText: String
        var statusLabel: String

        init(code: String, name: String, approved: String, region: String, copayText: String, version: String, startsAt: String, categoryText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.approved = approved
            self.region = region
            self.copayText = copayText
            self.version = version
            self.startsAt = startsAt
            self.categoryText = categoryText
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseRollupView(_ item: DispenseRollup) -> DispenseRollupView {
        return DispenseRollupView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            approved: "\(item.approved)",
            region: item.region,
            copayText: String(format: "%.2f", item.copay),
            version: String(item.version),
            startsAt: String(item.startsAt),
            categoryText: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseRollupViews(_ items: [DispenseRollup]) -> [DispenseRollupView] {
        var views: [DispenseRollupView] = []
        for item in items {
            views.append(toDispenseRollupView(item))
        }
        return views
    }

    static func sumDispenseRollupView(_ view: DispenseRollupView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedCopay + Double(parsedVersion) + Double(parsedStartsAt)
    }
}
