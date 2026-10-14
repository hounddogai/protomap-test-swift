import AcmePlatform
import Foundation

extension Referrals {
    /// Where a rolling closure profile is in its life cycle.
    enum RollingClosureProfileStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a rolling closure profile and its current status.
    final class RollingClosureProfile {
        var code: String
        var title: String
        var ward: String
        var diagnosisCode: String
        var cost: Double
        var dosageMg: Double
        var sequence: Int
        var status: RollingClosureProfileStatus

        init(code: String, title: String, ward: String, diagnosisCode: String, cost: Double, dosageMg: Double, sequence: Int, status: RollingClosureProfileStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.diagnosisCode = diagnosisCode
            self.cost = cost
            self.dosageMg = dosageMg
            self.sequence = sequence
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

        func canMoveTo(_ next: RollingClosureProfileStatus) -> Bool {
            switch status {
            case .idle:
                return next == RollingClosureProfileStatus.warming || next == RollingClosureProfileStatus.draining
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == RollingClosureProfileStatus.stopped
            case .draining:
                return next == RollingClosureProfileStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingClosureProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling closure profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rolling closure profile") \(code)"
        }

        func weightedVolume() -> Double {
            return ((cost - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> RollingClosureProfile {
            return RollingClosureProfile(
                code: code,
                title: title,
                ward: ward,
                diagnosisCode: diagnosisCode,
                cost: cost,
                dosageMg: dosageMg,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a rolling closure profile in status idle.
    static func newRollingClosureProfile(_ code: String, title: String) -> RollingClosureProfile {
        return RollingClosureProfile(
            code: code,
            title: title,
            ward: "",
            diagnosisCode: "",
            cost: 0.0,
            dosageMg: 0.0,
            sequence: 0,
            status: RollingClosureProfileStatus.idle
        )
    }
}
