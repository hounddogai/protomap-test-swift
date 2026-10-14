import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default risk score schedule is in its life cycle.
    enum DefaultRiskScoreScheduleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a default risk score schedule and its current status.
    final class DefaultRiskScoreSchedule {
        var code: String
        var name: String
        var discount: Double
        var summary: String
        var specialty: String
        var status: DefaultRiskScoreScheduleStatus

        init(code: String, name: String, discount: Double, summary: String, specialty: String, status: DefaultRiskScoreScheduleStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.summary = summary
            self.specialty = specialty
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultRiskScoreScheduleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == DefaultRiskScoreScheduleStatus.published || next == DefaultRiskScoreScheduleStatus.retired
            case .published:
                return next == DefaultRiskScoreScheduleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultRiskScoreScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default risk score schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> DefaultRiskScoreSchedule {
            return DefaultRiskScoreSchedule(
                code: code,
                name: name,
                discount: discount,
                summary: summary,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default risk score schedule in status created.
    static func newDefaultRiskScoreSchedule(_ code: String, name: String) -> DefaultRiskScoreSchedule {
        return DefaultRiskScoreSchedule(
            code: code,
            name: name,
            discount: 0.0,
            summary: "",
            specialty: "",
            status: DefaultRiskScoreScheduleStatus.created
        )
    }
}
