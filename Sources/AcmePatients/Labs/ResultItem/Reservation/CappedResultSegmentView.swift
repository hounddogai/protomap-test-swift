import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a capped result segment.
    final class CappedResultSegmentView {
        var codeText: String
        var label: String
        var ownerID: String
        var endsAt: String
        var facility: String
        var country: String
        var region: String
        var diagnosisCode: String
        var statusLabel: String

        init(codeText: String, label: String, ownerID: String, endsAt: String, facility: String, country: String, region: String, diagnosisCode: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.ownerID = ownerID
            self.endsAt = endsAt
            self.facility = facility
            self.country = country
            self.region = region
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toCappedResultSegmentView(_ item: CappedResultSegment) -> CappedResultSegmentView {
        return CappedResultSegmentView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            ownerID: item.ownerID,
            endsAt: String(item.endsAt),
            facility: item.facility,
            country: Kit.Text.truncate(item.country, limit: 80),
            region: Kit.Text.truncate(item.region, limit: 80),
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedResultSegmentViews(_ items: [CappedResultSegment]) -> [CappedResultSegmentView] {
        var views: [CappedResultSegmentView] = []
        for item in items {
            views.append(toCappedResultSegmentView(item))
        }
        return views
    }

    static func sumCappedResultSegmentView(_ view: CappedResultSegmentView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedEndsAt)
    }
}
