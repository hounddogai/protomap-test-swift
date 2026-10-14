import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance baseline.
    final class RemittanceBaselineView {
        var codeText: String
        var titleText: String
        var locale: String
        var reviewer: String
        var updatedAt: String
        var ownerIDText: String
        var patientRef: String
        var statusLabel: String

        init(codeText: String, titleText: String, locale: String, reviewer: String, updatedAt: String, ownerIDText: String, patientRef: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.locale = locale
            self.reviewer = reviewer
            self.updatedAt = updatedAt
            self.ownerIDText = ownerIDText
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceBaselineView(_ item: RemittanceBaseline) -> RemittanceBaselineView {
        return RemittanceBaselineView(
            codeText: item.code,
            titleText: item.title,
            locale: item.locale,
            reviewer: Kit.Text.truncate(item.reviewer, limit: 40),
            updatedAt: String(item.updatedAt),
            ownerIDText: item.ownerID,
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceBaselineViews(_ items: [RemittanceBaseline]) -> [RemittanceBaselineView] {
        var views: [RemittanceBaselineView] = []
        for item in items {
            views.append(toRemittanceBaselineView(item))
        }
        return views
    }

    static func sumRemittanceBaselineView(_ view: RemittanceBaselineView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedUpdatedAt)
    }
}
