import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a network entry.
    final class NetworkEntryView {
        var code: String
        var name: String
        var source: String
        var title: String
        var phoneText: String
        var diagnosisCode: String
        var ownerIDText: String
        var category: String
        var score: String
        var regionText: String
        var endsAt: String
        var statusLabel: String

        init(code: String, name: String, source: String, title: String, phoneText: String, diagnosisCode: String, ownerIDText: String, category: String, score: String, regionText: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.source = source
            self.title = title
            self.phoneText = phoneText
            self.diagnosisCode = diagnosisCode
            self.ownerIDText = ownerIDText
            self.category = category
            self.score = score
            self.regionText = regionText
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toNetworkEntryView(_ item: NetworkEntry) -> NetworkEntryView {
        return NetworkEntryView(
            code: item.code,
            name: item.name,
            source: item.source,
            title: item.title,
            phoneText: item.phone,
            diagnosisCode: item.diagnosisCode,
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 40),
            category: item.category,
            score: String(format: "%.2f", item.score),
            regionText: item.region,
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toNetworkEntryViews(_ items: [NetworkEntry]) -> [NetworkEntryView] {
        var views: [NetworkEntryView] = []
        for item in items {
            views.append(toNetworkEntryView(item))
        }
        return views
    }

    static func sumNetworkEntryView(_ view: NetworkEntryView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedScore + Double(parsedEndsAt)
    }
}
