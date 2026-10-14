import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a primary charge estimate is in its life cycle.
    enum PrimaryChargeEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A primary charge estimate. Its code is unique within a tenant.
    final class PrimaryChargeEstimate {
        var code: String
        var title: String
        var expiresAt: Int
        var approved: Bool
        var description: String
        var revision: Int
        var version: Int
        var status: PrimaryChargeEstimateStatus

        init(code: String, title: String, expiresAt: Int, approved: Bool, description: String, revision: Int, version: Int, status: PrimaryChargeEstimateStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.approved = approved
            self.description = description
            self.revision = revision
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryChargeEstimateStatus) -> Bool {
            switch status {
            case .requested:
                return next == PrimaryChargeEstimateStatus.expired
            case .granted:
                return next == PrimaryChargeEstimateStatus.revoked || next == PrimaryChargeEstimateStatus.expired
            case .revoked:
                return next == PrimaryChargeEstimateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryChargeEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary charge estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedVolume() -> Double {
            return ((Double(expiresAt) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryChargeEstimate {
            return PrimaryChargeEstimate(
                code: code,
                title: title,
                expiresAt: expiresAt,
                approved: approved,
                description: description,
                revision: revision,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary charge estimate in status requested.
    static func newPrimaryChargeEstimate(_ code: String, title: String) -> PrimaryChargeEstimate {
        return PrimaryChargeEstimate(
            code: code,
            title: title,
            expiresAt: 0,
            approved: false,
            description: "",
            revision: 0,
            version: 0,
            status: PrimaryChargeEstimateStatus.requested
        )
    }
}
