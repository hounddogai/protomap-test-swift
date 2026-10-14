import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a capped formulary milestone.
    final class CappedFormularyMilestoneView {
        var code: String
        var titleText: String
        var dosageMgText: String
        var capacity: String
        var endsAtText: String
        var refills: String
        var threshold: String
        var budget: String
        var ratioText: String
        var statusLabel: String

        init(code: String, titleText: String, dosageMgText: String, capacity: String, endsAtText: String, refills: String, threshold: String, budget: String, ratioText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.dosageMgText = dosageMgText
            self.capacity = capacity
            self.endsAtText = endsAtText
            self.refills = refills
            self.threshold = threshold
            self.budget = budget
            self.ratioText = ratioText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedFormularyMilestoneView(_ item: CappedFormularyMilestone) -> CappedFormularyMilestoneView {
        return CappedFormularyMilestoneView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 40),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            capacity: String(item.capacity),
            endsAtText: String(item.endsAt),
            refills: String(item.refills),
            threshold: String(format: "%.2f", item.threshold),
            budget: String(format: "%.2f", item.budget),
            ratioText: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedFormularyMilestoneViews(_ items: [CappedFormularyMilestone]) -> [CappedFormularyMilestoneView] {
        var views: [CappedFormularyMilestoneView] = []
        for item in items {
            views.append(toCappedFormularyMilestoneView(item))
        }
        return views
    }

    static func sumCappedFormularyMilestoneView(_ view: CappedFormularyMilestoneView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedDosageMg + Double(parsedCapacity) + Double(parsedEndsAt)
    }
}
