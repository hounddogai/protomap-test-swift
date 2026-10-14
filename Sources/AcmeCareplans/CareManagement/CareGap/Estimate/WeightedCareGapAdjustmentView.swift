import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a weighted care gap adjustment.
    final class WeightedCareGapAdjustmentView {
        var code: String
        var title: String
        var ownerID: String
        var marginText: String
        var expiresAt: String
        var score: String
        var capacity: String
        var unitText: String
        var active: String
        var countryText: String
        var patientRef: String
        var statusLabel: String

        init(code: String, title: String, ownerID: String, marginText: String, expiresAt: String, score: String, capacity: String, unitText: String, active: String, countryText: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.marginText = marginText
            self.expiresAt = expiresAt
            self.score = score
            self.capacity = capacity
            self.unitText = unitText
            self.active = active
            self.countryText = countryText
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedCareGapAdjustmentView(_ item: WeightedCareGapAdjustment) -> WeightedCareGapAdjustmentView {
        return WeightedCareGapAdjustmentView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            ownerID: item.ownerID,
            marginText: String(format: "%.2f", item.margin),
            expiresAt: String(item.expiresAt),
            score: String(format: "%.2f", item.score),
            capacity: String(item.capacity),
            unitText: item.unit,
            active: "\(item.active)",
            countryText: Kit.Text.truncate(item.country, limit: 64),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedCareGapAdjustmentViews(_ items: [WeightedCareGapAdjustment]) -> [WeightedCareGapAdjustmentView] {
        var views: [WeightedCareGapAdjustmentView] = []
        for item in items {
            views.append(toWeightedCareGapAdjustmentView(item))
        }
        return views
    }

    static func sumWeightedCareGapAdjustmentView(_ view: WeightedCareGapAdjustmentView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedMargin + Double(parsedExpiresAt) + parsedScore
    }
}
