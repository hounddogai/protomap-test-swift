import AcmePlatform
import Foundation

extension Consent {
    /// Where a pending revocation claim is in its life cycle.
    enum PendingRevocationClaimStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One pending revocation claim, with what the planners need to act on it.
    final class PendingRevocationClaim {
        var code: String
        var title: String
        var version: Int
        var limit: Int
        var name: String
        var region: String
        var facility: String
        var checksum: String
        var payer: String
        var status: PendingRevocationClaimStatus

        init(code: String, title: String, version: Int, limit: Int, name: String, region: String, facility: String, checksum: String, payer: String, status: PendingRevocationClaimStatus) {
            self.code = code
            self.title = title
            self.version = version
            self.limit = limit
            self.name = name
            self.region = region
            self.facility = facility
            self.checksum = checksum
            self.payer = payer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingRevocationClaimStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == PendingRevocationClaimStatus.inProgress
            case .inProgress:
                return next == PendingRevocationClaimStatus.completed || next == PendingRevocationClaimStatus.cancelled
            case .completed:
                return next == PendingRevocationClaimStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingRevocationClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending revocation claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedVolume() -> Double {
            return (Double(limit) * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> PendingRevocationClaim {
            return PendingRevocationClaim(
                code: code,
                title: title,
                version: version,
                limit: limit,
                name: name,
                region: region,
                facility: facility,
                checksum: checksum,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a pending revocation claim in status planned.
    static func newPendingRevocationClaim(_ code: String, title: String) -> PendingRevocationClaim {
        return PendingRevocationClaim(
            code: code,
            title: title,
            version: 0,
            limit: 0,
            name: "",
            region: "",
            facility: "",
            checksum: "",
            payer: "",
            status: PendingRevocationClaimStatus.planned
        )
    }
}
