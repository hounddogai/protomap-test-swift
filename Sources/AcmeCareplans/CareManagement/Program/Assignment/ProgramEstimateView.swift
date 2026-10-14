import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program estimate.
    final class ProgramEstimateView {
        var codeText: String
        var title: String
        var retries: String
        var costText: String
        var segmentText: String
        var approved: String
        var statusLabel: String

        init(codeText: String, title: String, retries: String, costText: String, segmentText: String, approved: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.retries = retries
            self.costText = costText
            self.segmentText = segmentText
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toProgramEstimateView(_ item: ProgramEstimate) -> ProgramEstimateView {
        return ProgramEstimateView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            retries: String(item.retries),
            costText: String(format: "%.2f", item.cost),
            segmentText: item.segment,
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramEstimateViews(_ items: [ProgramEstimate]) -> [ProgramEstimateView] {
        var views: [ProgramEstimateView] = []
        for item in items {
            views.append(toProgramEstimateView(item))
        }
        return views
    }

    static func sumProgramEstimateView(_ view: ProgramEstimateView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedRetries) + parsedCost
    }
}
