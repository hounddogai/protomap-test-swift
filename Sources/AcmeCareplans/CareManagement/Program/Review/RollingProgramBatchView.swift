import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a rolling program batch.
    final class RollingProgramBatchView {
        var code: String
        var name: String
        var archived: String
        var weight: String
        var batchSize: String
        var procedureCodeText: String
        var floorValueText: String
        var title: String
        var rate: String
        var statusLabel: String

        init(code: String, name: String, archived: String, weight: String, batchSize: String, procedureCodeText: String, floorValueText: String, title: String, rate: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.archived = archived
            self.weight = weight
            self.batchSize = batchSize
            self.procedureCodeText = procedureCodeText
            self.floorValueText = floorValueText
            self.title = title
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toRollingProgramBatchView(_ item: RollingProgramBatch) -> RollingProgramBatchView {
        return RollingProgramBatchView(
            code: item.code,
            name: item.name,
            archived: "\(item.archived)",
            weight: String(format: "%.2f", item.weight),
            batchSize: String(item.batchSize),
            procedureCodeText: item.procedureCode,
            floorValueText: String(format: "%.2f", item.floorValue),
            title: item.title,
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingProgramBatchViews(_ items: [RollingProgramBatch]) -> [RollingProgramBatchView] {
        var views: [RollingProgramBatchView] = []
        for item in items {
            views.append(toRollingProgramBatchView(item))
        }
        return views
    }

    static func sumRollingProgramBatchView(_ view: RollingProgramBatchView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedWeight + Double(parsedBatchSize) + parsedFloorValue
    }
}
