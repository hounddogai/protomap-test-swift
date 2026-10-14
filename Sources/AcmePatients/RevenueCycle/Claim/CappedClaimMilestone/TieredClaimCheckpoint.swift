import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered claim checkpoint is in its life cycle.
    enum TieredClaimCheckpointStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One tiered claim checkpoint, with what the planners need to act on it.
    final class TieredClaimCheckpoint {
        var code: String
        var label: String
        var diagnosisCode: String
        var source: String
        var updatedAt: Int
        var country: String
        var summary: String
        var status: TieredClaimCheckpointStatus

        init(code: String, label: String, diagnosisCode: String, source: String, updatedAt: Int, country: String, summary: String, status: TieredClaimCheckpointStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.source = source
            self.updatedAt = updatedAt
            self.country = country
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

        func canMoveTo(_ next: TieredClaimCheckpointStatus) -> Bool {
            switch status {
            case .requested:
                return next == TieredClaimCheckpointStatus.revoked
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

        func moveTo(_ next: TieredClaimCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered claim checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("tiered claim checkpoint") \(code)"
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> TieredClaimCheckpoint {
            return TieredClaimCheckpoint(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                source: source,
                updatedAt: updatedAt,
                country: country,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a tiered claim checkpoint in status requested.
    static func newTieredClaimCheckpoint(_ code: String, label: String) -> TieredClaimCheckpoint {
        return TieredClaimCheckpoint(
            code: code,
            label: label,
            diagnosisCode: "",
            source: "",
            updatedAt: 0,
            country: "",
            summary: "",
            status: TieredClaimCheckpointStatus.requested
        )
    }
}
