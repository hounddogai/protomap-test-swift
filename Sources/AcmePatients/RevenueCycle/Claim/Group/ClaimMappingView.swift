import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim mapping.
    final class ClaimMappingView {
        var codeText: String
        var name: String
        var retriesText: String
        var margin: String
        var archived: String
        var durationMinutes: String
        var statusLabel: String

        init(codeText: String, name: String, retriesText: String, margin: String, archived: String, durationMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.retriesText = retriesText
            self.margin = margin
            self.archived = archived
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toClaimMappingView(_ item: ClaimMapping) -> ClaimMappingView {
        return ClaimMappingView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            retriesText: String(item.retries),
            margin: String(format: "%.2f", item.margin),
            archived: "\(item.archived)",
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimMappingViews(_ items: [ClaimMapping]) -> [ClaimMappingView] {
        var views: [ClaimMappingView] = []
        for item in items {
            views.append(toClaimMappingView(item))
        }
        return views
    }

    static func sumClaimMappingView(_ view: ClaimMappingView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedRetries) + parsedMargin + Double(parsedDurationMinutes)
    }
}
