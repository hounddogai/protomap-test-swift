import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a denial allocation.
    final class DenialAllocationView {
        var codeText: String
        var title: String
        var durationMinutes: String
        var archivedText: String
        var reviewerText: String
        var externalRef: String
        var ownerID: String
        var statusLabel: String

        init(codeText: String, title: String, durationMinutes: String, archivedText: String, reviewerText: String, externalRef: String, ownerID: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.durationMinutes = durationMinutes
            self.archivedText = archivedText
            self.reviewerText = reviewerText
            self.externalRef = externalRef
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toDenialAllocationView(_ item: DenialAllocation) -> DenialAllocationView {
        return DenialAllocationView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            durationMinutes: String(item.durationMinutes),
            archivedText: "\(item.archived)",
            reviewerText: item.reviewer,
            externalRef: item.externalRef,
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDenialAllocationViews(_ items: [DenialAllocation]) -> [DenialAllocationView] {
        var views: [DenialAllocationView] = []
        for item in items {
            views.append(toDenialAllocationView(item))
        }
        return views
    }

    static func sumDenialAllocationView(_ view: DenialAllocationView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedDurationMinutes)
    }
}
