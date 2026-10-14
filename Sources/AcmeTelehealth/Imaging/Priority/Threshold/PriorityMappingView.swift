import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority mapping.
    final class PriorityMappingView {
        var code: String
        var nameText: String
        var visitMinutesText: String
        var checksumText: String
        var ratio: String
        var category: String
        var unitText: String
        var ceiling: String
        var batchSize: String
        var encounterID: String
        var ownerID: String
        var statusLabel: String

        init(code: String, nameText: String, visitMinutesText: String, checksumText: String, ratio: String, category: String, unitText: String, ceiling: String, batchSize: String, encounterID: String, ownerID: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.visitMinutesText = visitMinutesText
            self.checksumText = checksumText
            self.ratio = ratio
            self.category = category
            self.unitText = unitText
            self.ceiling = ceiling
            self.batchSize = batchSize
            self.encounterID = encounterID
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityMappingView(_ item: PriorityMapping) -> PriorityMappingView {
        return PriorityMappingView(
            code: Kit.Text.truncate(item.code, limit: 120),
            nameText: Kit.Text.truncate(item.name, limit: 40),
            visitMinutesText: String(item.visitMinutes),
            checksumText: item.checksum,
            ratio: String(format: "%.2f", item.ratio),
            category: item.category,
            unitText: item.unit,
            ceiling: String(format: "%.2f", item.ceiling),
            batchSize: String(item.batchSize),
            encounterID: item.encounterID,
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityMappingViews(_ items: [PriorityMapping]) -> [PriorityMappingView] {
        var views: [PriorityMappingView] = []
        for item in items {
            views.append(toPriorityMappingView(item))
        }
        return views
    }

    static func sumPriorityMappingView(_ view: PriorityMappingView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedVisitMinutes) + parsedRatio + parsedCeiling
    }
}
