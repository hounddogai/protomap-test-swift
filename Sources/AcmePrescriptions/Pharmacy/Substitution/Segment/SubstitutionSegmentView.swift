import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a substitution segment.
    final class SubstitutionSegmentView {
        var code: String
        var label: String
        var bedText: String
        var expiresAt: String
        var checksumText: String
        var statusLabel: String

        init(code: String, label: String, bedText: String, expiresAt: String, checksumText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.bedText = bedText
            self.expiresAt = expiresAt
            self.checksumText = checksumText
            self.statusLabel = statusLabel
        }
    }

    static func toSubstitutionSegmentView(_ item: SubstitutionSegment) -> SubstitutionSegmentView {
        return SubstitutionSegmentView(
            code: item.code,
            label: item.label,
            bedText: Kit.Text.truncate(item.bed, limit: 80),
            expiresAt: String(item.expiresAt),
            checksumText: Kit.Text.truncate(item.checksum, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSubstitutionSegmentViews(_ items: [SubstitutionSegment]) -> [SubstitutionSegmentView] {
        var views: [SubstitutionSegmentView] = []
        for item in items {
            views.append(toSubstitutionSegmentView(item))
        }
        return views
    }

    static func sumSubstitutionSegmentView(_ view: SubstitutionSegmentView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedExpiresAt)
    }
}
