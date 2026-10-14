import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol cycle.
    final class CareProtocolCycleView {
        var codeText: String
        var name: String
        var facilityText: String
        var region: String
        var summaryText: String
        var clinicianID: String
        var score: String
        var statusLabel: String

        init(codeText: String, name: String, facilityText: String, region: String, summaryText: String, clinicianID: String, score: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.facilityText = facilityText
            self.region = region
            self.summaryText = summaryText
            self.clinicianID = clinicianID
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolCycleView(_ item: CareProtocolCycle) -> CareProtocolCycleView {
        return CareProtocolCycleView(
            codeText: item.code,
            name: item.name,
            facilityText: item.facility,
            region: Kit.Text.truncate(item.region, limit: 64),
            summaryText: Kit.Text.truncate(item.summary, limit: 80),
            clinicianID: item.clinicianID,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolCycleViews(_ items: [CareProtocolCycle]) -> [CareProtocolCycleView] {
        var views: [CareProtocolCycleView] = []
        for item in items {
            views.append(toCareProtocolCycleView(item))
        }
        return views
    }

    static func sumCareProtocolCycleView(_ view: CareProtocolCycleView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
