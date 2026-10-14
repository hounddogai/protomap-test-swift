import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read mapping.
    final class ReadMappingView {
        var code: String
        var name: String
        var createdAt: String
        var allergyText: String
        var limit: String
        var dosageMg: String
        var specialty: String
        var batchSizeText: String
        var floorValue: String
        var region: String
        var statusLabel: String

        init(code: String, name: String, createdAt: String, allergyText: String, limit: String, dosageMg: String, specialty: String, batchSizeText: String, floorValue: String, region: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.allergyText = allergyText
            self.limit = limit
            self.dosageMg = dosageMg
            self.specialty = specialty
            self.batchSizeText = batchSizeText
            self.floorValue = floorValue
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toReadMappingView(_ item: ReadMapping) -> ReadMappingView {
        return ReadMappingView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            createdAt: String(item.createdAt),
            allergyText: item.allergy,
            limit: String(item.limit),
            dosageMg: String(format: "%.2f", item.dosageMg),
            specialty: item.specialty,
            batchSizeText: String(item.batchSize),
            floorValue: String(format: "%.2f", item.floorValue),
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadMappingViews(_ items: [ReadMapping]) -> [ReadMappingView] {
        var views: [ReadMappingView] = []
        for item in items {
            views.append(toReadMappingView(item))
        }
        return views
    }

    static func sumReadMappingView(_ view: ReadMappingView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedLimit) + parsedDosageMg
    }
}
