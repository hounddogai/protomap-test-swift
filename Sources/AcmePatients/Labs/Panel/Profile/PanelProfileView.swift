import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel profile.
    final class PanelProfileView {
        var code: String
        var nameText: String
        var reviewerText: String
        var summaryText: String
        var currency: String
        var phoneText: String
        var country: String
        var retriesText: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, nameText: String, reviewerText: String, summaryText: String, currency: String, phoneText: String, country: String, retriesText: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.reviewerText = reviewerText
            self.summaryText = summaryText
            self.currency = currency
            self.phoneText = phoneText
            self.country = country
            self.retriesText = retriesText
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toPanelProfileView(_ item: PanelProfile) -> PanelProfileView {
        return PanelProfileView(
            code: item.code,
            nameText: item.name,
            reviewerText: item.reviewer,
            summaryText: item.summary,
            currency: Kit.Text.truncate(item.currency, limit: 40),
            phoneText: item.phone,
            country: item.country,
            retriesText: String(item.retries),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelProfileViews(_ items: [PanelProfile]) -> [PanelProfileView] {
        var views: [PanelProfileView] = []
        for item in items {
            views.append(toPanelProfileView(item))
        }
        return views
    }

    static func sumPanelProfileView(_ view: PanelProfileView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedRetries) + parsedDosageMg
    }
}
