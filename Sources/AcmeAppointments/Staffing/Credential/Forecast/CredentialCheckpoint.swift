import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential checkpoint is in its life cycle.
    enum CredentialCheckpointStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a credential checkpoint and its current status.
    final class CredentialCheckpoint {
        var code: String
        var name: String
        var region: String
        var diagnosisCode: String
        var limit: Int
        var status: CredentialCheckpointStatus

        init(code: String, name: String, region: String, diagnosisCode: String, limit: Int, status: CredentialCheckpointStatus) {
            self.code = code
            self.name = name
            self.region = region
            self.diagnosisCode = diagnosisCode
            self.limit = limit
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

        func canMoveTo(_ next: CredentialCheckpointStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
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
                return next == CredentialCheckpointStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> CredentialCheckpoint {
            return CredentialCheckpoint(
                code: code,
                name: name,
                region: region,
                diagnosisCode: diagnosisCode,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a credential checkpoint in status requested.
    static func newCredentialCheckpoint(_ code: String, name: String) -> CredentialCheckpoint {
        return CredentialCheckpoint(
            code: code,
            name: name,
            region: "",
            diagnosisCode: "",
            limit: 0,
            status: CredentialCheckpointStatus.requested
        )
    }
}
