import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol metric.
    final class CareProtocolMetricView {
        var code: String
        var nameText: String
        var specialty: String
        var bed: String
        var description: String
        var refills: String
        var priorityText: String
        var revisionText: String
        var encounterID: String
        var statusLabel: String

        init(code: String, nameText: String, specialty: String, bed: String, description: String, refills: String, priorityText: String, revisionText: String, encounterID: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.specialty = specialty
            self.bed = bed
            self.description = description
            self.refills = refills
            self.priorityText = priorityText
            self.revisionText = revisionText
            self.encounterID = encounterID
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolMetricView(_ item: CareProtocolMetric) -> CareProtocolMetricView {
        return CareProtocolMetricView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 64),
            specialty: item.specialty,
            bed: item.bed,
            description: item.description,
            refills: String(item.refills),
            priorityText: String(item.priority),
            revisionText: String(item.revision),
            encounterID: item.encounterID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolMetricViews(_ items: [CareProtocolMetric]) -> [CareProtocolMetricView] {
        var views: [CareProtocolMetricView] = []
        for item in items {
            views.append(toCareProtocolMetricView(item))
        }
        return views
    }

    static func sumCareProtocolMetricView(_ view: CareProtocolMetricView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedRefills) + Double(parsedPriority) + Double(parsedRevision)
    }
}
