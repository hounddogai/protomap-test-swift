import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality rollup.
    final class ModalityRollupView {
        var codeText: String
        var titleText: String
        var budget: String
        var reviewerText: String
        var bedText: String
        var ward: String
        var version: String
        var statusLabel: String

        init(codeText: String, titleText: String, budget: String, reviewerText: String, bedText: String, ward: String, version: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.budget = budget
            self.reviewerText = reviewerText
            self.bedText = bedText
            self.ward = ward
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toModalityRollupView(_ item: ModalityRollup) -> ModalityRollupView {
        return ModalityRollupView(
            codeText: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            budget: String(format: "%.2f", item.budget),
            reviewerText: item.reviewer,
            bedText: item.bed,
            ward: item.ward,
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityRollupViews(_ items: [ModalityRollup]) -> [ModalityRollupView] {
        var views: [ModalityRollupView] = []
        for item in items {
            views.append(toModalityRollupView(item))
        }
        return views
    }

    static func sumModalityRollupView(_ view: ModalityRollupView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedBudget + Double(parsedVersion)
    }
}
