import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility exception is in its life cycle.
    enum EligibilityExceptionStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A eligibility exception as the eligibility team keeps it.
    final class EligibilityException {
        var code: String
        var name: String
        var attributes: [String: String]
        var country: String
        var maximum: Double
        var status: EligibilityExceptionStatus

        init(code: String, name: String, attributes: [String: String], country: String, maximum: Double, status: EligibilityExceptionStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.country = country
            self.maximum = maximum
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

        func canMoveTo(_ next: EligibilityExceptionStatus) -> Bool {
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
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == EligibilityExceptionStatus.completed
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

        func moveTo(_ next: EligibilityExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("eligibility exception") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> EligibilityException {
            return EligibilityException(
                code: code,
                name: name,
                attributes: attributes,
                country: country,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a eligibility exception in status planned.
    static func newEligibilityException(_ code: String, name: String) -> EligibilityException {
        return EligibilityException(
            code: code,
            name: name,
            attributes: [:],
            country: "",
            maximum: 0.0,
            status: EligibilityExceptionStatus.planned
        )
    }
}
