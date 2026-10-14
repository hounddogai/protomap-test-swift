import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a tiered care gap adjustment.
    final class TieredCareGapAdjustmentView {
        var code: String
        var title: String
        var patientRef: String
        var clinicianID: String
        var ratio: String
        var score: String
        var dosageMg: String
        var ceilingText: String
        var visitMinutes: String
        var floorValue: String
        var statusLabel: String

        init(code: String, title: String, patientRef: String, clinicianID: String, ratio: String, score: String, dosageMg: String, ceilingText: String, visitMinutes: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.clinicianID = clinicianID
            self.ratio = ratio
            self.score = score
            self.dosageMg = dosageMg
            self.ceilingText = ceilingText
            self.visitMinutes = visitMinutes
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toTieredCareGapAdjustmentView(_ item: TieredCareGapAdjustment) -> TieredCareGapAdjustmentView {
        return TieredCareGapAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 120),
            clinicianID: item.clinicianID,
            ratio: String(format: "%.2f", item.ratio),
            score: String(format: "%.2f", item.score),
            dosageMg: String(format: "%.2f", item.dosageMg),
            ceilingText: String(format: "%.2f", item.ceiling),
            visitMinutes: String(item.visitMinutes),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredCareGapAdjustmentViews(_ items: [TieredCareGapAdjustment]) -> [TieredCareGapAdjustmentView] {
        var views: [TieredCareGapAdjustmentView] = []
        for item in items {
            views.append(toTieredCareGapAdjustmentView(item))
        }
        return views
    }

    static func sumTieredCareGapAdjustmentView(_ view: TieredCareGapAdjustmentView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedRatio + parsedScore + parsedDosageMg
    }
}
