import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach summary.
    final class OutreachSummaryView {
        var codeText: String
        var title: String
        var specialty: String
        var externalRef: String
        var clinicianID: String
        var allergy: String
        var unitText: String
        var bed: String
        var capacity: String
        var statusLabel: String

        init(codeText: String, title: String, specialty: String, externalRef: String, clinicianID: String, allergy: String, unitText: String, bed: String, capacity: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.specialty = specialty
            self.externalRef = externalRef
            self.clinicianID = clinicianID
            self.allergy = allergy
            self.unitText = unitText
            self.bed = bed
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachSummaryView(_ item: OutreachSummary) -> OutreachSummaryView {
        return OutreachSummaryView(
            codeText: item.code,
            title: item.title,
            specialty: Kit.Text.truncate(item.specialty, limit: 120),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 120),
            clinicianID: item.clinicianID,
            allergy: item.allergy,
            unitText: item.unit,
            bed: Kit.Text.truncate(item.bed, limit: 80),
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachSummaryViews(_ items: [OutreachSummary]) -> [OutreachSummaryView] {
        var views: [OutreachSummaryView] = []
        for item in items {
            views.append(toOutreachSummaryView(item))
        }
        return views
    }

    static func sumOutreachSummaryView(_ view: OutreachSummaryView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedCapacity)
    }
}
