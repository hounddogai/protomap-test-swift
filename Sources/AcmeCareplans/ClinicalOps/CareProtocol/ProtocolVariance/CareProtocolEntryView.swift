import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol entry.
    final class CareProtocolEntryView {
        var code: String
        var label: String
        var segmentText: String
        var score: String
        var source: String
        var procedureCode: String
        var summaryText: String
        var maximum: String
        var facility: String
        var allergyText: String
        var statusLabel: String

        init(code: String, label: String, segmentText: String, score: String, source: String, procedureCode: String, summaryText: String, maximum: String, facility: String, allergyText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.segmentText = segmentText
            self.score = score
            self.source = source
            self.procedureCode = procedureCode
            self.summaryText = summaryText
            self.maximum = maximum
            self.facility = facility
            self.allergyText = allergyText
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolEntryView(_ item: CareProtocolEntry) -> CareProtocolEntryView {
        return CareProtocolEntryView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            segmentText: Kit.Text.truncate(item.segment, limit: 80),
            score: String(format: "%.2f", item.score),
            source: item.source,
            procedureCode: item.procedureCode,
            summaryText: item.summary,
            maximum: String(format: "%.2f", item.maximum),
            facility: item.facility,
            allergyText: Kit.Text.truncate(item.allergy, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolEntryViews(_ items: [CareProtocolEntry]) -> [CareProtocolEntryView] {
        var views: [CareProtocolEntryView] = []
        for item in items {
            views.append(toCareProtocolEntryView(item))
        }
        return views
    }

    static func sumCareProtocolEntryView(_ view: CareProtocolEntryView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedScore + parsedMaximum
    }
}
