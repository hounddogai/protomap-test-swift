import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol schedule.
    final class CareProtocolScheduleView {
        var codeText: String
        var title: String
        var batchSizeText: String
        var channel: String
        var approvedText: String
        var attemptsText: String
        var budget: String
        var copayText: String
        var externalRefText: String
        var ratio: String
        var procedureCode: String
        var statusLabel: String

        init(codeText: String, title: String, batchSizeText: String, channel: String, approvedText: String, attemptsText: String, budget: String, copayText: String, externalRefText: String, ratio: String, procedureCode: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.batchSizeText = batchSizeText
            self.channel = channel
            self.approvedText = approvedText
            self.attemptsText = attemptsText
            self.budget = budget
            self.copayText = copayText
            self.externalRefText = externalRefText
            self.ratio = ratio
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolScheduleView(_ item: CareProtocolSchedule) -> CareProtocolScheduleView {
        return CareProtocolScheduleView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            batchSizeText: String(item.batchSize),
            channel: item.channel,
            approvedText: "\(item.approved)",
            attemptsText: String(item.attempts),
            budget: String(format: "%.2f", item.budget),
            copayText: String(format: "%.2f", item.copay),
            externalRefText: item.externalRef,
            ratio: String(format: "%.2f", item.ratio),
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolScheduleViews(_ items: [CareProtocolSchedule]) -> [CareProtocolScheduleView] {
        var views: [CareProtocolScheduleView] = []
        for item in items {
            views.append(toCareProtocolScheduleView(item))
        }
        return views
    }

    static func sumCareProtocolScheduleView(_ view: CareProtocolScheduleView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedAttempts) + parsedBudget
    }
}
