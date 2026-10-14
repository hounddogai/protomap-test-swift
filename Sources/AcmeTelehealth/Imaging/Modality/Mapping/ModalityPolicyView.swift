import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality policy.
    final class ModalityPolicyView {
        var codeText: String
        var name: String
        var visibleText: String
        var budget: String
        var specialty: String
        var updatedAtText: String
        var ratio: String
        var reviewerText: String
        var rate: String
        var windowDays: String
        var dosageMg: String
        var statusLabel: String

        init(codeText: String, name: String, visibleText: String, budget: String, specialty: String, updatedAtText: String, ratio: String, reviewerText: String, rate: String, windowDays: String, dosageMg: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.visibleText = visibleText
            self.budget = budget
            self.specialty = specialty
            self.updatedAtText = updatedAtText
            self.ratio = ratio
            self.reviewerText = reviewerText
            self.rate = rate
            self.windowDays = windowDays
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toModalityPolicyView(_ item: ModalityPolicy) -> ModalityPolicyView {
        return ModalityPolicyView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: Kit.Text.truncate(item.name, limit: 64),
            visibleText: "\(item.visible)",
            budget: String(format: "%.2f", item.budget),
            specialty: Kit.Text.truncate(item.specialty, limit: 120),
            updatedAtText: String(item.updatedAt),
            ratio: String(format: "%.2f", item.ratio),
            reviewerText: item.reviewer,
            rate: String(format: "%.2f", item.rate),
            windowDays: String(item.windowDays),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityPolicyViews(_ items: [ModalityPolicy]) -> [ModalityPolicyView] {
        var views: [ModalityPolicyView] = []
        for item in items {
            views.append(toModalityPolicyView(item))
        }
        return views
    }

    static func sumModalityPolicyView(_ view: ModalityPolicyView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedBudget + Double(parsedUpdatedAt) + parsedRatio
    }
}
