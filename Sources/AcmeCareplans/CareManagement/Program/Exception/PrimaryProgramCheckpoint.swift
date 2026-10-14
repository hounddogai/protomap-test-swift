import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a primary program checkpoint is in its life cycle.
    enum PrimaryProgramCheckpointStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A primary program checkpoint. Its code is unique within a tenant.
    final class PrimaryProgramCheckpoint {
        var code: String
        var title: String
        var source: String
        var durationMinutes: Int
        var diagnosisCode: String
        var startsAt: Int
        var attempts: Int
        var cost: Double
        var status: PrimaryProgramCheckpointStatus

        init(code: String, title: String, source: String, durationMinutes: Int, diagnosisCode: String, startsAt: Int, attempts: Int, cost: Double, status: PrimaryProgramCheckpointStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.durationMinutes = durationMinutes
            self.diagnosisCode = diagnosisCode
            self.startsAt = startsAt
            self.attempts = attempts
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryProgramCheckpointStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == PrimaryProgramCheckpointStatus.draining || next == PrimaryProgramCheckpointStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: PrimaryProgramCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary program checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveValue() -> Double {
            return ((Double(durationMinutes) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryProgramCheckpoint {
            return PrimaryProgramCheckpoint(
                code: code,
                title: title,
                source: source,
                durationMinutes: durationMinutes,
                diagnosisCode: diagnosisCode,
                startsAt: startsAt,
                attempts: attempts,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a primary program checkpoint in status idle.
    static func newPrimaryProgramCheckpoint(_ code: String, title: String) -> PrimaryProgramCheckpoint {
        return PrimaryProgramCheckpoint(
            code: code,
            title: title,
            source: "",
            durationMinutes: 0,
            diagnosisCode: "",
            startsAt: 0,
            attempts: 0,
            cost: 0.0,
            status: PrimaryProgramCheckpointStatus.idle
        )
    }
}
