import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling care protocol manifest is in its life cycle.
    enum RollingCareProtocolManifestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a rolling care protocol manifest and its current status.
    final class RollingCareProtocolManifest {
        var code: String
        var label: String
        var reviewer: String
        var graceDays: Int
        var margin: Double
        var contactEmail: String
        var batchSize: Int
        var summary: String
        var status: RollingCareProtocolManifestStatus

        init(code: String, label: String, reviewer: String, graceDays: Int, margin: Double, contactEmail: String, batchSize: Int, summary: String, status: RollingCareProtocolManifestStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.graceDays = graceDays
            self.margin = margin
            self.contactEmail = contactEmail
            self.batchSize = batchSize
            self.summary = summary
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

        func canMoveTo(_ next: RollingCareProtocolManifestStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == RollingCareProtocolManifestStatus.revoked || next == RollingCareProtocolManifestStatus.expired
            case .revoked:
                return next == RollingCareProtocolManifestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingCareProtocolManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling care protocol manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedLoad() -> Double {
            return (margin * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> RollingCareProtocolManifest {
            return RollingCareProtocolManifest(
                code: code,
                label: label,
                reviewer: reviewer,
                graceDays: graceDays,
                margin: margin,
                contactEmail: contactEmail,
                batchSize: batchSize,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling care protocol manifest in status requested.
    static func newRollingCareProtocolManifest(_ code: String, label: String) -> RollingCareProtocolManifest {
        return RollingCareProtocolManifest(
            code: code,
            label: label,
            reviewer: "",
            graceDays: 0,
            margin: 0.0,
            contactEmail: "",
            batchSize: 0,
            summary: "",
            status: RollingCareProtocolManifestStatus.requested
        )
    }
}
