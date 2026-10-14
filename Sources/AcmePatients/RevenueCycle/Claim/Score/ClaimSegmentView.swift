import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim segment.
    final class ClaimSegmentView {
        var code: String
        var label: String
        var visitMinutes: String
        var ceiling: String
        var patientRef: String
        var limitText: String
        var durationMinutes: String
        var startsAt: String
        var statusLabel: String

        init(code: String, label: String, visitMinutes: String, ceiling: String, patientRef: String, limitText: String, durationMinutes: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.ceiling = ceiling
            self.patientRef = patientRef
            self.limitText = limitText
            self.durationMinutes = durationMinutes
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toClaimSegmentView(_ item: ClaimSegment) -> ClaimSegmentView {
        return ClaimSegmentView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            visitMinutes: String(item.visitMinutes),
            ceiling: String(format: "%.2f", item.ceiling),
            patientRef: item.patientRef,
            limitText: String(item.limit),
            durationMinutes: String(item.durationMinutes),
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimSegmentViews(_ items: [ClaimSegment]) -> [ClaimSegmentView] {
        var views: [ClaimSegmentView] = []
        for item in items {
            views.append(toClaimSegmentView(item))
        }
        return views
    }

    static func sumClaimSegmentView(_ view: ClaimSegmentView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedVisitMinutes) + parsedCeiling + Double(parsedLimit)
    }
}
