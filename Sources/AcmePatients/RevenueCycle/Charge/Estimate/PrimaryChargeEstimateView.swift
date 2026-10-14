import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a primary charge estimate.
    final class PrimaryChargeEstimateView {
        var code: String
        var title: String
        var expiresAt: String
        var approved: String
        var description: String
        var revision: String
        var version: String
        var statusLabel: String

        init(code: String, title: String, expiresAt: String, approved: String, description: String, revision: String, version: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.approved = approved
            self.description = description
            self.revision = revision
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryChargeEstimateView(_ item: PrimaryChargeEstimate) -> PrimaryChargeEstimateView {
        return PrimaryChargeEstimateView(
            code: item.code,
            title: item.title,
            expiresAt: String(item.expiresAt),
            approved: "\(item.approved)",
            description: Kit.Text.truncate(item.description, limit: 64),
            revision: String(item.revision),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryChargeEstimateViews(_ items: [PrimaryChargeEstimate]) -> [PrimaryChargeEstimateView] {
        var views: [PrimaryChargeEstimateView] = []
        for item in items {
            views.append(toPrimaryChargeEstimateView(item))
        }
        return views
    }

    static func sumPrimaryChargeEstimateView(_ view: PrimaryChargeEstimateView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedRevision) + Double(parsedVersion)
    }
}
