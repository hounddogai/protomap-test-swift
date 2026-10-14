import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result cycle.
    final class ResultCycleView {
        var code: String
        var nameText: String
        var discountText: String
        var batchSizeText: String
        var specialty: String
        var approved: String
        var procedureCode: String
        var visitMinutes: String
        var visibleText: String
        var channel: String
        var statusLabel: String

        init(code: String, nameText: String, discountText: String, batchSizeText: String, specialty: String, approved: String, procedureCode: String, visitMinutes: String, visibleText: String, channel: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.discountText = discountText
            self.batchSizeText = batchSizeText
            self.specialty = specialty
            self.approved = approved
            self.procedureCode = procedureCode
            self.visitMinutes = visitMinutes
            self.visibleText = visibleText
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toResultCycleView(_ item: ResultCycle) -> ResultCycleView {
        return ResultCycleView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            discountText: String(format: "%.2f", item.discount),
            batchSizeText: String(item.batchSize),
            specialty: Kit.Text.truncate(item.specialty, limit: 80),
            approved: "\(item.approved)",
            procedureCode: item.procedureCode,
            visitMinutes: String(item.visitMinutes),
            visibleText: "\(item.visible)",
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultCycleViews(_ items: [ResultCycle]) -> [ResultCycleView] {
        var views: [ResultCycleView] = []
        for item in items {
            views.append(toResultCycleView(item))
        }
        return views
    }

    static func sumResultCycleView(_ view: ResultCycleView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedDiscount + Double(parsedBatchSize) + Double(parsedVisitMinutes)
    }
}
