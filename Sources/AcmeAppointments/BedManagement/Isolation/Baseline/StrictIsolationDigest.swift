import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a strict isolation digest is in its life cycle.
    enum StrictIsolationDigestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A strict isolation digest as the isolation team keeps it.
    final class StrictIsolationDigest {
        var code: String
        var title: String
        var attempts: Int
        var threshold: Double
        var clinicianID: String
        var floorValue: Double
        var status: StrictIsolationDigestStatus

        init(code: String, title: String, attempts: Int, threshold: Double, clinicianID: String, floorValue: Double, status: StrictIsolationDigestStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.threshold = threshold
            self.clinicianID = clinicianID
            self.floorValue = floorValue
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

        func canMoveTo(_ next: StrictIsolationDigestStatus) -> Bool {
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
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictIsolationDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict isolation digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveExposure() -> Double {
            return (Double(attempts) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> StrictIsolationDigest {
            return StrictIsolationDigest(
                code: code,
                title: title,
                attempts: attempts,
                threshold: threshold,
                clinicianID: clinicianID,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict isolation digest in status requested.
    static func newStrictIsolationDigest(_ code: String, title: String) -> StrictIsolationDigest {
        return StrictIsolationDigest(
            code: code,
            title: title,
            attempts: 0,
            threshold: 0.0,
            clinicianID: "",
            floorValue: 0.0,
            status: StrictIsolationDigestStatus.requested
        )
    }
}
