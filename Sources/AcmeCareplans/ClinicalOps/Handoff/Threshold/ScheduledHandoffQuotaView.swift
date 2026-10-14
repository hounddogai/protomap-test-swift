import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a scheduled handoff quota.
    final class ScheduledHandoffQuotaView {
        var codeText: String
        var name: String
        var patientRefText: String
        var cost: String
        var retries: String
        var label: String
        var floorValueText: String
        var bed: String
        var budget: String
        var statusLabel: String

        init(codeText: String, name: String, patientRefText: String, cost: String, retries: String, label: String, floorValueText: String, bed: String, budget: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.patientRefText = patientRefText
            self.cost = cost
            self.retries = retries
            self.label = label
            self.floorValueText = floorValueText
            self.bed = bed
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledHandoffQuotaView(_ item: ScheduledHandoffQuota) -> ScheduledHandoffQuotaView {
        return ScheduledHandoffQuotaView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            patientRefText: item.patientRef,
            cost: String(format: "%.2f", item.cost),
            retries: String(item.retries),
            label: item.label,
            floorValueText: String(format: "%.2f", item.floorValue),
            bed: item.bed,
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledHandoffQuotaViews(_ items: [ScheduledHandoffQuota]) -> [ScheduledHandoffQuotaView] {
        var views: [ScheduledHandoffQuotaView] = []
        for item in items {
            views.append(toScheduledHandoffQuotaView(item))
        }
        return views
    }

    static func sumScheduledHandoffQuotaView(_ view: ScheduledHandoffQuotaView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedCost + Double(parsedRetries) + parsedFloorValue
    }
}
