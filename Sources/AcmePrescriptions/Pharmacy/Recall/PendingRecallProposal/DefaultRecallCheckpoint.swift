import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default recall checkpoint is in its life cycle.
    enum DefaultRecallCheckpointStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A default recall checkpoint as the recall team keeps it.
    final class DefaultRecallCheckpoint {
        var code: String
        var name: String
        var diagnosisCode: String
        var minimum: Double
        var startsAt: Int
        var limit: Int
        var procedureCode: String
        var status: DefaultRecallCheckpointStatus

        init(code: String, name: String, diagnosisCode: String, minimum: Double, startsAt: Int, limit: Int, procedureCode: String, status: DefaultRecallCheckpointStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.minimum = minimum
            self.startsAt = startsAt
            self.limit = limit
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultRecallCheckpointStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == DefaultRecallCheckpointStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultRecallCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default recall checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("default recall checkpoint") \(code)"
        }

        func netExposure() -> Double {
            return (minimum * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> DefaultRecallCheckpoint {
            return DefaultRecallCheckpoint(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                minimum: minimum,
                startsAt: startsAt,
                limit: limit,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default recall checkpoint in status proposed.
    static func newDefaultRecallCheckpoint(_ code: String, name: String) -> DefaultRecallCheckpoint {
        return DefaultRecallCheckpoint(
            code: code,
            name: name,
            diagnosisCode: "",
            minimum: 0.0,
            startsAt: 0,
            limit: 0,
            procedureCode: "",
            status: DefaultRecallCheckpointStatus.proposed
        )
    }
}
