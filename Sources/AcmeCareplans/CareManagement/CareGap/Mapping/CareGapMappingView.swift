import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap mapping.
    final class CareGapMappingView {
        var codeText: String
        var name: String
        var version: String
        var ceilingText: String
        var priority: String
        var region: String
        var notes: String
        var limit: String
        var phone: String
        var ratio: String
        var budgetText: String
        var statusLabel: String

        init(codeText: String, name: String, version: String, ceilingText: String, priority: String, region: String, notes: String, limit: String, phone: String, ratio: String, budgetText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.version = version
            self.ceilingText = ceilingText
            self.priority = priority
            self.region = region
            self.notes = notes
            self.limit = limit
            self.phone = phone
            self.ratio = ratio
            self.budgetText = budgetText
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapMappingView(_ item: CareGapMapping) -> CareGapMappingView {
        return CareGapMappingView(
            codeText: item.code,
            name: item.name,
            version: String(item.version),
            ceilingText: String(format: "%.2f", item.ceiling),
            priority: String(item.priority),
            region: Kit.Text.truncate(item.region, limit: 80),
            notes: item.notes,
            limit: String(item.limit),
            phone: item.phone,
            ratio: String(format: "%.2f", item.ratio),
            budgetText: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapMappingViews(_ items: [CareGapMapping]) -> [CareGapMappingView] {
        var views: [CareGapMappingView] = []
        for item in items {
            views.append(toCareGapMappingView(item))
        }
        return views
    }

    static func sumCareGapMappingView(_ view: CareGapMappingView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedVersion) + parsedCeiling + Double(parsedPriority)
    }
}
