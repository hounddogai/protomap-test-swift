import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a network rollup.
    final class NetworkRollupView {
        var codeText: String
        var name: String
        var threshold: String
        var reviewer: String
        var endsAtText: String
        var region: String
        var specialtyText: String
        var archived: String
        var weight: String
        var bedText: String
        var phone: String
        var statusLabel: String

        init(codeText: String, name: String, threshold: String, reviewer: String, endsAtText: String, region: String, specialtyText: String, archived: String, weight: String, bedText: String, phone: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.threshold = threshold
            self.reviewer = reviewer
            self.endsAtText = endsAtText
            self.region = region
            self.specialtyText = specialtyText
            self.archived = archived
            self.weight = weight
            self.bedText = bedText
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toNetworkRollupView(_ item: NetworkRollup) -> NetworkRollupView {
        return NetworkRollupView(
            codeText: item.code,
            name: item.name,
            threshold: String(format: "%.2f", item.threshold),
            reviewer: item.reviewer,
            endsAtText: String(item.endsAt),
            region: item.region,
            specialtyText: item.specialty,
            archived: "\(item.archived)",
            weight: String(format: "%.2f", item.weight),
            bedText: item.bed,
            phone: Kit.Text.truncate(item.phone, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toNetworkRollupViews(_ items: [NetworkRollup]) -> [NetworkRollupView] {
        var views: [NetworkRollupView] = []
        for item in items {
            views.append(toNetworkRollupView(item))
        }
        return views
    }

    static func sumNetworkRollupView(_ view: NetworkRollupView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedThreshold + Double(parsedEndsAt) + parsedWeight
    }
}
