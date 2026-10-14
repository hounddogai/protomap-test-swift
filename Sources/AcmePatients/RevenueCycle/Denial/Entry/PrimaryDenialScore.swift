import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a primary denial score is in its life cycle.
    enum PrimaryDenialScoreStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One primary denial score, with what the planners need to act on it.
    final class PrimaryDenialScore {
        var code: String
        var name: String
        var budget: Double
        var timezone: String
        var specialty: String
        var procedureCode: String
        var copay: Double
        var status: PrimaryDenialScoreStatus

        init(code: String, name: String, budget: Double, timezone: String, specialty: String, procedureCode: String, copay: Double, status: PrimaryDenialScoreStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.timezone = timezone
            self.specialty = specialty
            self.procedureCode = procedureCode
            self.copay = copay
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

        func canMoveTo(_ next: PrimaryDenialScoreStatus) -> Bool {
            switch status {
            case .planned:
                return next == PrimaryDenialScoreStatus.scheduled
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: PrimaryDenialScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary denial score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary denial score") \(code)"
        }

        func projectedVolume() -> Double {
            return ((copay - budget) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryDenialScore {
            return PrimaryDenialScore(
                code: code,
                name: name,
                budget: budget,
                timezone: timezone,
                specialty: specialty,
                procedureCode: procedureCode,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary denial score in status planned.
    static func newPrimaryDenialScore(_ code: String, name: String) -> PrimaryDenialScore {
        return PrimaryDenialScore(
            code: code,
            name: name,
            budget: 0.0,
            timezone: "",
            specialty: "",
            procedureCode: "",
            copay: 0.0,
            status: PrimaryDenialScoreStatus.planned
        )
    }
}
