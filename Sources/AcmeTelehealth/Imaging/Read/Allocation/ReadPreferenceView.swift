import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read preference.
    final class ReadPreferenceView {
        var code: String
        var label: String
        var region: String
        var cost: String
        var phone: String
        var endsAtText: String
        var copay: String
        var bed: String
        var batchSizeText: String
        var expiresAt: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, label: String, region: String, cost: String, phone: String, endsAtText: String, copay: String, bed: String, batchSizeText: String, expiresAt: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.region = region
            self.cost = cost
            self.phone = phone
            self.endsAtText = endsAtText
            self.copay = copay
            self.bed = bed
            self.batchSizeText = batchSizeText
            self.expiresAt = expiresAt
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toReadPreferenceView(_ item: ReadPreference) -> ReadPreferenceView {
        return ReadPreferenceView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            region: item.region,
            cost: String(format: "%.2f", item.cost),
            phone: Kit.Text.truncate(item.phone, limit: 40),
            endsAtText: String(item.endsAt),
            copay: String(format: "%.2f", item.copay),
            bed: item.bed,
            batchSizeText: String(item.batchSize),
            expiresAt: String(item.expiresAt),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadPreferenceViews(_ items: [ReadPreference]) -> [ReadPreferenceView] {
        var views: [ReadPreferenceView] = []
        for item in items {
            views.append(toReadPreferenceView(item))
        }
        return views
    }

    static func sumReadPreferenceView(_ view: ReadPreferenceView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCost + Double(parsedEndsAt) + parsedCopay
    }
}
