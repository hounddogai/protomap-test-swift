import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality baseline.
    final class ModalityBaselineView {
        var code: String
        var label: String
        var facility: String
        var checksum: String
        var ceilingText: String
        var weight: String
        var allergy: String
        var limit: String
        var visitMinutes: String
        var createdAtText: String
        var region: String
        var statusLabel: String

        init(code: String, label: String, facility: String, checksum: String, ceilingText: String, weight: String, allergy: String, limit: String, visitMinutes: String, createdAtText: String, region: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.facility = facility
            self.checksum = checksum
            self.ceilingText = ceilingText
            self.weight = weight
            self.allergy = allergy
            self.limit = limit
            self.visitMinutes = visitMinutes
            self.createdAtText = createdAtText
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toModalityBaselineView(_ item: ModalityBaseline) -> ModalityBaselineView {
        return ModalityBaselineView(
            code: item.code,
            label: item.label,
            facility: item.facility,
            checksum: item.checksum,
            ceilingText: String(format: "%.2f", item.ceiling),
            weight: String(format: "%.2f", item.weight),
            allergy: item.allergy,
            limit: String(item.limit),
            visitMinutes: String(item.visitMinutes),
            createdAtText: String(item.createdAt),
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityBaselineViews(_ items: [ModalityBaseline]) -> [ModalityBaselineView] {
        var views: [ModalityBaselineView] = []
        for item in items {
            views.append(toModalityBaselineView(item))
        }
        return views
    }

    static func sumModalityBaselineView(_ view: ModalityBaselineView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedCeiling + parsedWeight + Double(parsedLimit)
    }
}
