import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy review.
    final class ProxyReviewView {
        var code: String
        var nameText: String
        var phone: String
        var checksumText: String
        var ward: String
        var facilityText: String
        var retries: String
        var reviewer: String
        var statusLabel: String

        init(code: String, nameText: String, phone: String, checksumText: String, ward: String, facilityText: String, retries: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.phone = phone
            self.checksumText = checksumText
            self.ward = ward
            self.facilityText = facilityText
            self.retries = retries
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toProxyReviewView(_ item: ProxyReview) -> ProxyReviewView {
        return ProxyReviewView(
            code: Kit.Text.truncate(item.code, limit: 64),
            nameText: item.name,
            phone: item.phone,
            checksumText: Kit.Text.truncate(item.checksum, limit: 120),
            ward: item.ward,
            facilityText: Kit.Text.truncate(item.facility, limit: 64),
            retries: String(item.retries),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyReviewViews(_ items: [ProxyReview]) -> [ProxyReviewView] {
        var views: [ProxyReviewView] = []
        for item in items {
            views.append(toProxyReviewView(item))
        }
        return views
    }

    static func sumProxyReviewView(_ view: ProxyReviewView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedRetries)
    }
}
