import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study group.
    final class StudyGroupView {
        var code: String
        var name: String
        var limitText: String
        var minimum: String
        var facility: String
        var threshold: String
        var acuityText: String
        var createdAt: String
        var maximum: String
        var currencyText: String
        var statusLabel: String

        init(code: String, name: String, limitText: String, minimum: String, facility: String, threshold: String, acuityText: String, createdAt: String, maximum: String, currencyText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.limitText = limitText
            self.minimum = minimum
            self.facility = facility
            self.threshold = threshold
            self.acuityText = acuityText
            self.createdAt = createdAt
            self.maximum = maximum
            self.currencyText = currencyText
            self.statusLabel = statusLabel
        }
    }

    static func toStudyGroupView(_ item: StudyGroup) -> StudyGroupView {
        return StudyGroupView(
            code: item.code,
            name: item.name,
            limitText: String(item.limit),
            minimum: String(format: "%.2f", item.minimum),
            facility: item.facility,
            threshold: String(format: "%.2f", item.threshold),
            acuityText: String(item.acuity),
            createdAt: String(item.createdAt),
            maximum: String(format: "%.2f", item.maximum),
            currencyText: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyGroupViews(_ items: [StudyGroup]) -> [StudyGroupView] {
        var views: [StudyGroupView] = []
        for item in items {
            views.append(toStudyGroupView(item))
        }
        return views
    }

    static func sumStudyGroupView(_ view: StudyGroupView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedLimit) + parsedMinimum + parsedThreshold
    }
}
