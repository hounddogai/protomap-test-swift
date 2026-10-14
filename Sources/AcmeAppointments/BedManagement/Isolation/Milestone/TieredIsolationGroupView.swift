import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a tiered isolation group.
    final class TieredIsolationGroupView {
        var code: String
        var name: String
        var segment: String
        var scoreText: String
        var contactEmailText: String
        var facility: String
        var visitMinutes: String
        var priorityText: String
        var region: String
        var checksumText: String
        var bed: String
        var statusLabel: String

        init(code: String, name: String, segment: String, scoreText: String, contactEmailText: String, facility: String, visitMinutes: String, priorityText: String, region: String, checksumText: String, bed: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.segment = segment
            self.scoreText = scoreText
            self.contactEmailText = contactEmailText
            self.facility = facility
            self.visitMinutes = visitMinutes
            self.priorityText = priorityText
            self.region = region
            self.checksumText = checksumText
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toTieredIsolationGroupView(_ item: TieredIsolationGroup) -> TieredIsolationGroupView {
        return TieredIsolationGroupView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            segment: item.segment,
            scoreText: String(format: "%.2f", item.score),
            contactEmailText: item.contactEmail,
            facility: item.facility,
            visitMinutes: String(item.visitMinutes),
            priorityText: String(item.priority),
            region: item.region,
            checksumText: item.checksum,
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredIsolationGroupViews(_ items: [TieredIsolationGroup]) -> [TieredIsolationGroupView] {
        var views: [TieredIsolationGroupView] = []
        for item in items {
            views.append(toTieredIsolationGroupView(item))
        }
        return views
    }

    static func sumTieredIsolationGroupView(_ view: TieredIsolationGroupView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedScore + Double(parsedVisitMinutes) + Double(parsedPriority)
    }
}
