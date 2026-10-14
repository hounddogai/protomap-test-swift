import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a scheduled claim tier.
    final class ScheduledClaimTierView {
        var codeText: String
        var name: String
        var visibleText: String
        var ward: String
        var diagnosisCodeText: String
        var ownerID: String
        var sourceText: String
        var threshold: String
        var statusLabel: String

        init(codeText: String, name: String, visibleText: String, ward: String, diagnosisCodeText: String, ownerID: String, sourceText: String, threshold: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.visibleText = visibleText
            self.ward = ward
            self.diagnosisCodeText = diagnosisCodeText
            self.ownerID = ownerID
            self.sourceText = sourceText
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledClaimTierView(_ item: ScheduledClaimTier) -> ScheduledClaimTierView {
        return ScheduledClaimTierView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            visibleText: "\(item.visible)",
            ward: Kit.Text.truncate(item.ward, limit: 80),
            diagnosisCodeText: item.diagnosisCode,
            ownerID: item.ownerID,
            sourceText: item.source,
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledClaimTierViews(_ items: [ScheduledClaimTier]) -> [ScheduledClaimTierView] {
        var views: [ScheduledClaimTierView] = []
        for item in items {
            views.append(toScheduledClaimTierView(item))
        }
        return views
    }

    static func sumScheduledClaimTierView(_ view: ScheduledClaimTierView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedThreshold
    }
}
