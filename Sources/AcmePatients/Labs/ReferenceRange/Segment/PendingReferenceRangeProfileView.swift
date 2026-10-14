import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a pending reference range profile.
    final class PendingReferenceRangeProfileView {
        var code: String
        var label: String
        var visible: String
        var revision: String
        var createdAt: String
        var statusLabel: String

        init(code: String, label: String, visible: String, revision: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.visible = visible
            self.revision = revision
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toPendingReferenceRangeProfileView(_ item: PendingReferenceRangeProfile) -> PendingReferenceRangeProfileView {
        return PendingReferenceRangeProfileView(
            code: item.code,
            label: item.label,
            visible: "\(item.visible)",
            revision: String(item.revision),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingReferenceRangeProfileViews(_ items: [PendingReferenceRangeProfile]) -> [PendingReferenceRangeProfileView] {
        var views: [PendingReferenceRangeProfileView] = []
        for item in items {
            views.append(toPendingReferenceRangeProfileView(item))
        }
        return views
    }

    static func sumPendingReferenceRangeProfileView(_ view: PendingReferenceRangeProfileView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedRevision) + Double(parsedCreatedAt)
    }
}
