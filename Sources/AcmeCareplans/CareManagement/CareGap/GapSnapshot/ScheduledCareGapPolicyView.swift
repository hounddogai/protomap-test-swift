import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a scheduled care gap policy.
    final class ScheduledCareGapPolicyView {
        var code: String
        var nameText: String
        var pinned: String
        var quantity: String
        var diagnosisCodeText: String
        var description: String
        var sourceText: String
        var category: String
        var windowDays: String
        var statusLabel: String

        init(code: String, nameText: String, pinned: String, quantity: String, diagnosisCodeText: String, description: String, sourceText: String, category: String, windowDays: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.pinned = pinned
            self.quantity = quantity
            self.diagnosisCodeText = diagnosisCodeText
            self.description = description
            self.sourceText = sourceText
            self.category = category
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledCareGapPolicyView(_ item: ScheduledCareGapPolicy) -> ScheduledCareGapPolicyView {
        return ScheduledCareGapPolicyView(
            code: Kit.Text.truncate(item.code, limit: 120),
            nameText: item.name,
            pinned: "\(item.pinned)",
            quantity: String(item.quantity),
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            description: item.description,
            sourceText: item.source,
            category: item.category,
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledCareGapPolicyViews(_ items: [ScheduledCareGapPolicy]) -> [ScheduledCareGapPolicyView] {
        var views: [ScheduledCareGapPolicyView] = []
        for item in items {
            views.append(toScheduledCareGapPolicyView(item))
        }
        return views
    }

    static func sumScheduledCareGapPolicyView(_ view: ScheduledCareGapPolicyView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedQuantity) + Double(parsedWindowDays)
    }
}
