import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance tier.
    final class RemittanceTierView {
        var code: String
        var title: String
        var clinicianID: String
        var refills: String
        var visitMinutesText: String
        var archived: String
        var createdAt: String
        var revisionText: String
        var statusLabel: String

        init(code: String, title: String, clinicianID: String, refills: String, visitMinutesText: String, archived: String, createdAt: String, revisionText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.refills = refills
            self.visitMinutesText = visitMinutesText
            self.archived = archived
            self.createdAt = createdAt
            self.revisionText = revisionText
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceTierView(_ item: RemittanceTier) -> RemittanceTierView {
        return RemittanceTierView(
            code: item.code,
            title: item.title,
            clinicianID: item.clinicianID,
            refills: String(item.refills),
            visitMinutesText: String(item.visitMinutes),
            archived: "\(item.archived)",
            createdAt: String(item.createdAt),
            revisionText: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceTierViews(_ items: [RemittanceTier]) -> [RemittanceTierView] {
        var views: [RemittanceTierView] = []
        for item in items {
            views.append(toRemittanceTierView(item))
        }
        return views
    }

    static func sumRemittanceTierView(_ view: RemittanceTierView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedRefills) + Double(parsedVisitMinutes) + Double(parsedCreatedAt)
    }
}
