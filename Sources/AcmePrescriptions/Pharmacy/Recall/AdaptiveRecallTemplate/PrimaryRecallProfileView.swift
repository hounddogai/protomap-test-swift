import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a primary recall profile.
    final class PrimaryRecallProfileView {
        var code: String
        var name: String
        var visitMinutes: String
        var copayText: String
        var reviewerText: String
        var statusLabel: String

        init(code: String, name: String, visitMinutes: String, copayText: String, reviewerText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.copayText = copayText
            self.reviewerText = reviewerText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryRecallProfileView(_ item: PrimaryRecallProfile) -> PrimaryRecallProfileView {
        return PrimaryRecallProfileView(
            code: item.code,
            name: item.name,
            visitMinutes: String(item.visitMinutes),
            copayText: String(format: "%.2f", item.copay),
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryRecallProfileViews(_ items: [PrimaryRecallProfile]) -> [PrimaryRecallProfileView] {
        var views: [PrimaryRecallProfileView] = []
        for item in items {
            views.append(toPrimaryRecallProfileView(item))
        }
        return views
    }

    static func sumPrimaryRecallProfileView(_ view: PrimaryRecallProfileView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedVisitMinutes) + parsedCopay
    }
}
