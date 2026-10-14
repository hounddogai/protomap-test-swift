import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation digest.
    final class RevocationDigestView {
        var code: String
        var title: String
        var acuity: String
        var segmentText: String
        var phone: String
        var marginText: String
        var reviewer: String
        var statusLabel: String

        init(code: String, title: String, acuity: String, segmentText: String, phone: String, marginText: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.segmentText = segmentText
            self.phone = phone
            self.marginText = marginText
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationDigestView(_ item: RevocationDigest) -> RevocationDigestView {
        return RevocationDigestView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            acuity: String(item.acuity),
            segmentText: item.segment,
            phone: item.phone,
            marginText: String(format: "%.2f", item.margin),
            reviewer: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationDigestViews(_ items: [RevocationDigest]) -> [RevocationDigestView] {
        var views: [RevocationDigestView] = []
        for item in items {
            views.append(toRevocationDigestView(item))
        }
        return views
    }

    static func sumRevocationDigestView(_ view: RevocationDigestView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedAcuity) + parsedMargin
    }
}
