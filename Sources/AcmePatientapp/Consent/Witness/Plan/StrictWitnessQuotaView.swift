import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a strict witness quota.
    final class StrictWitnessQuotaView {
        var codeText: String
        var title: String
        var budget: String
        var capacityText: String
        var procedureCodeText: String
        var visitMinutes: String
        var segment: String
        var summaryText: String
        var reviewer: String
        var statusLabel: String

        init(codeText: String, title: String, budget: String, capacityText: String, procedureCodeText: String, visitMinutes: String, segment: String, summaryText: String, reviewer: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.budget = budget
            self.capacityText = capacityText
            self.procedureCodeText = procedureCodeText
            self.visitMinutes = visitMinutes
            self.segment = segment
            self.summaryText = summaryText
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toStrictWitnessQuotaView(_ item: StrictWitnessQuota) -> StrictWitnessQuotaView {
        return StrictWitnessQuotaView(
            codeText: item.code,
            title: item.title,
            budget: String(format: "%.2f", item.budget),
            capacityText: String(item.capacity),
            procedureCodeText: item.procedureCode,
            visitMinutes: String(item.visitMinutes),
            segment: item.segment,
            summaryText: item.summary,
            reviewer: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictWitnessQuotaViews(_ items: [StrictWitnessQuota]) -> [StrictWitnessQuotaView] {
        var views: [StrictWitnessQuotaView] = []
        for item in items {
            views.append(toStrictWitnessQuotaView(item))
        }
        return views
    }

    static func sumStrictWitnessQuotaView(_ view: StrictWitnessQuotaView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedBudget + Double(parsedCapacity) + Double(parsedVisitMinutes)
    }
}
