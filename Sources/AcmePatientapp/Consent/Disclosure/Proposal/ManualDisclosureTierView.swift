import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a manual disclosure tier.
    final class ManualDisclosureTierView {
        var code: String
        var name: String
        var sequence: String
        var startsAt: String
        var facility: String
        var revisionText: String
        var statusLabel: String

        init(code: String, name: String, sequence: String, startsAt: String, facility: String, revisionText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.startsAt = startsAt
            self.facility = facility
            self.revisionText = revisionText
            self.statusLabel = statusLabel
        }
    }

    static func toManualDisclosureTierView(_ item: ManualDisclosureTier) -> ManualDisclosureTierView {
        return ManualDisclosureTierView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            sequence: String(item.sequence),
            startsAt: String(item.startsAt),
            facility: Kit.Text.truncate(item.facility, limit: 80),
            revisionText: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualDisclosureTierViews(_ items: [ManualDisclosureTier]) -> [ManualDisclosureTierView] {
        var views: [ManualDisclosureTierView] = []
        for item in items {
            views.append(toManualDisclosureTierView(item))
        }
        return views
    }

    static func sumManualDisclosureTierView(_ view: ManualDisclosureTierView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedSequence) + Double(parsedStartsAt) + Double(parsedRevision)
    }
}
