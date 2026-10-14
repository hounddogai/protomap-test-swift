import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a tiered authorization cycle.
    final class TieredAuthorizationCycleView {
        var code: String
        var name: String
        var facilityText: String
        var revision: String
        var sequenceText: String
        var country: String
        var segmentText: String
        var summaryText: String
        var timezone: String
        var statusLabel: String

        init(code: String, name: String, facilityText: String, revision: String, sequenceText: String, country: String, segmentText: String, summaryText: String, timezone: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.facilityText = facilityText
            self.revision = revision
            self.sequenceText = sequenceText
            self.country = country
            self.segmentText = segmentText
            self.summaryText = summaryText
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toTieredAuthorizationCycleView(_ item: TieredAuthorizationCycle) -> TieredAuthorizationCycleView {
        return TieredAuthorizationCycleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            facilityText: item.facility,
            revision: String(item.revision),
            sequenceText: String(item.sequence),
            country: Kit.Text.truncate(item.country, limit: 40),
            segmentText: item.segment,
            summaryText: item.summary,
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredAuthorizationCycleViews(_ items: [TieredAuthorizationCycle]) -> [TieredAuthorizationCycleView] {
        var views: [TieredAuthorizationCycleView] = []
        for item in items {
            views.append(toTieredAuthorizationCycleView(item))
        }
        return views
    }

    static func sumTieredAuthorizationCycleView(_ view: TieredAuthorizationCycleView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedRevision) + Double(parsedSequence)
    }
}
