import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a network template.
    final class NetworkTemplateView {
        var codeText: String
        var label: String
        var dosageMgText: String
        var maximumText: String
        var minimum: String
        var startsAt: String
        var checksum: String
        var summary: String
        var region: String
        var statusLabel: String

        init(codeText: String, label: String, dosageMgText: String, maximumText: String, minimum: String, startsAt: String, checksum: String, summary: String, region: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.dosageMgText = dosageMgText
            self.maximumText = maximumText
            self.minimum = minimum
            self.startsAt = startsAt
            self.checksum = checksum
            self.summary = summary
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toNetworkTemplateView(_ item: NetworkTemplate) -> NetworkTemplateView {
        return NetworkTemplateView(
            codeText: item.code,
            label: item.label,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            maximumText: String(format: "%.2f", item.maximum),
            minimum: String(format: "%.2f", item.minimum),
            startsAt: String(item.startsAt),
            checksum: item.checksum,
            summary: item.summary,
            region: Kit.Text.truncate(item.region, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toNetworkTemplateViews(_ items: [NetworkTemplate]) -> [NetworkTemplateView] {
        var views: [NetworkTemplateView] = []
        for item in items {
            views.append(toNetworkTemplateView(item))
        }
        return views
    }

    static func sumNetworkTemplateView(_ view: NetworkTemplateView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedDosageMg + parsedMaximum + parsedMinimum
    }
}
