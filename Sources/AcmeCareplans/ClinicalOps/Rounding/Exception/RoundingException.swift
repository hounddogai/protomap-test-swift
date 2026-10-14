import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding exception is in its life cycle.
    enum RoundingExceptionStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One rounding exception, with what the planners need to act on it.
    final class RoundingException {
        var code: String
        var name: String
        var description: String
        var sequence: Int
        var country: String
        var status: RoundingExceptionStatus

        init(code: String, name: String, description: String, sequence: Int, country: String, status: RoundingExceptionStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.sequence = sequence
            self.country = country
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

        func canMoveTo(_ next: RoundingExceptionStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == RoundingExceptionStatus.completed || next == RoundingExceptionStatus.cancelled
            case .completed:
                return next == RoundingExceptionStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RoundingExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(sequence)
        }

        func copyValue() -> RoundingException {
            return RoundingException(
                code: code,
                name: name,
                description: description,
                sequence: sequence,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a rounding exception in status planned.
    static func newRoundingException(_ code: String, name: String) -> RoundingException {
        return RoundingException(
            code: code,
            name: name,
            description: "",
            sequence: 0,
            country: "",
            status: RoundingExceptionStatus.planned
        )
    }
}
