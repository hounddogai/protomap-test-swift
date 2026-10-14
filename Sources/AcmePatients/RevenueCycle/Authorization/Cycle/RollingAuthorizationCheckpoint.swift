import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a rolling authorization checkpoint is in its life cycle.
    enum RollingAuthorizationCheckpointStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A rolling authorization checkpoint. Its code is unique within a tenant.
    final class RollingAuthorizationCheckpoint {
        var code: String
        var name: String
        var attempts: Int
        var cost: Double
        var visitMinutes: Int
        var notes: String
        var margin: Double
        var category: String
        var sequence: Int
        var batchSize: Int
        var status: RollingAuthorizationCheckpointStatus

        init(code: String, name: String, attempts: Int, cost: Double, visitMinutes: Int, notes: String, margin: Double, category: String, sequence: Int, batchSize: Int, status: RollingAuthorizationCheckpointStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.cost = cost
            self.visitMinutes = visitMinutes
            self.notes = notes
            self.margin = margin
            self.category = category
            self.sequence = sequence
            self.batchSize = batchSize
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

        func canMoveTo(_ next: RollingAuthorizationCheckpointStatus) -> Bool {
            switch status {
            case .requested:
                return next == RollingAuthorizationCheckpointStatus.revoked || next == RollingAuthorizationCheckpointStatus.expired
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

        func moveTo(_ next: RollingAuthorizationCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling authorization checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedVolume() -> Double {
            return ((margin - cost) * 100).rounded() / 100
        }

        func copyValue() -> RollingAuthorizationCheckpoint {
            return RollingAuthorizationCheckpoint(
                code: code,
                name: name,
                attempts: attempts,
                cost: cost,
                visitMinutes: visitMinutes,
                notes: notes,
                margin: margin,
                category: category,
                sequence: sequence,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a rolling authorization checkpoint in status requested.
    static func newRollingAuthorizationCheckpoint(_ code: String, name: String) -> RollingAuthorizationCheckpoint {
        return RollingAuthorizationCheckpoint(
            code: code,
            name: name,
            attempts: 0,
            cost: 0.0,
            visitMinutes: 0,
            notes: "",
            margin: 0.0,
            category: "",
            sequence: 0,
            batchSize: 0,
            status: RollingAuthorizationCheckpointStatus.requested
        )
    }
}
