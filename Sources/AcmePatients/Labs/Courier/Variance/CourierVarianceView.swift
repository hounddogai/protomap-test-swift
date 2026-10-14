import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier variance.
    final class CourierVarianceView {
        var code: String
        var labelText: String
        var threshold: String
        var visibleText: String
        var visitMinutesText: String
        var createdAtText: String
        var updatedAt: String
        var ceiling: String
        var active: String
        var externalRefText: String
        var allergy: String
        var statusLabel: String

        init(code: String, labelText: String, threshold: String, visibleText: String, visitMinutesText: String, createdAtText: String, updatedAt: String, ceiling: String, active: String, externalRefText: String, allergy: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.threshold = threshold
            self.visibleText = visibleText
            self.visitMinutesText = visitMinutesText
            self.createdAtText = createdAtText
            self.updatedAt = updatedAt
            self.ceiling = ceiling
            self.active = active
            self.externalRefText = externalRefText
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toCourierVarianceView(_ item: CourierVariance) -> CourierVarianceView {
        return CourierVarianceView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: Kit.Text.truncate(item.label, limit: 64),
            threshold: String(format: "%.2f", item.threshold),
            visibleText: "\(item.visible)",
            visitMinutesText: String(item.visitMinutes),
            createdAtText: String(item.createdAt),
            updatedAt: String(item.updatedAt),
            ceiling: String(format: "%.2f", item.ceiling),
            active: "\(item.active)",
            externalRefText: item.externalRef,
            allergy: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierVarianceViews(_ items: [CourierVariance]) -> [CourierVarianceView] {
        var views: [CourierVarianceView] = []
        for item in items {
            views.append(toCourierVarianceView(item))
        }
        return views
    }

    static func sumCourierVarianceView(_ view: CourierVarianceView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedThreshold + Double(parsedVisitMinutes) + Double(parsedCreatedAt)
    }
}
