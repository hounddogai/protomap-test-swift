import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a rolling charge segment.
    final class RollingChargeSegmentView {
        var code: String
        var name: String
        var capacity: String
        var revisionText: String
        var scoreText: String
        var unit: String
        var statusLabel: String

        init(code: String, name: String, capacity: String, revisionText: String, scoreText: String, unit: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.revisionText = revisionText
            self.scoreText = scoreText
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toRollingChargeSegmentView(_ item: RollingChargeSegment) -> RollingChargeSegmentView {
        return RollingChargeSegmentView(
            code: item.code,
            name: item.name,
            capacity: String(item.capacity),
            revisionText: String(item.revision),
            scoreText: String(format: "%.2f", item.score),
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingChargeSegmentViews(_ items: [RollingChargeSegment]) -> [RollingChargeSegmentView] {
        var views: [RollingChargeSegmentView] = []
        for item in items {
            views.append(toRollingChargeSegmentView(item))
        }
        return views
    }

    static func sumRollingChargeSegmentView(_ view: RollingChargeSegmentView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedCapacity) + Double(parsedRevision) + parsedScore
    }
}
