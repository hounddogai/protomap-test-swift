import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a lenient care gap allocation.
    final class LenientCareGapAllocationView {
        var codeText: String
        var title: String
        var capacity: String
        var active: String
        var summary: String
        var visitMinutes: String
        var weight: String
        var locale: String
        var unit: String
        var statusLabel: String

        init(codeText: String, title: String, capacity: String, active: String, summary: String, visitMinutes: String, weight: String, locale: String, unit: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.capacity = capacity
            self.active = active
            self.summary = summary
            self.visitMinutes = visitMinutes
            self.weight = weight
            self.locale = locale
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toLenientCareGapAllocationView(_ item: LenientCareGapAllocation) -> LenientCareGapAllocationView {
        return LenientCareGapAllocationView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            capacity: String(item.capacity),
            active: "\(item.active)",
            summary: item.summary,
            visitMinutes: String(item.visitMinutes),
            weight: String(format: "%.2f", item.weight),
            locale: item.locale,
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientCareGapAllocationViews(_ items: [LenientCareGapAllocation]) -> [LenientCareGapAllocationView] {
        var views: [LenientCareGapAllocationView] = []
        for item in items {
            views.append(toLenientCareGapAllocationView(item))
        }
        return views
    }

    static func sumLenientCareGapAllocationView(_ view: LenientCareGapAllocationView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedCapacity) + Double(parsedVisitMinutes) + parsedWeight
    }
}
