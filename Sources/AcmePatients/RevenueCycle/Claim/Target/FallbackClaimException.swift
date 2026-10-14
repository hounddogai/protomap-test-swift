import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback claim exception is in its life cycle.
    enum FallbackClaimExceptionStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A fallback claim exception as the claim team keeps it.
    final class FallbackClaimException {
        var code: String
        var label: String
        var specialty: String
        var active: Bool
        var priority: Int
        var name: String
        var budget: Double
        var allergy: String
        var rate: Double
        var contactEmail: String
        var weight: Double
        var status: FallbackClaimExceptionStatus

        init(code: String, label: String, specialty: String, active: Bool, priority: Int, name: String, budget: Double, allergy: String, rate: Double, contactEmail: String, weight: Double, status: FallbackClaimExceptionStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.active = active
            self.priority = priority
            self.name = name
            self.budget = budget
            self.allergy = allergy
            self.rate = rate
            self.contactEmail = contactEmail
            self.weight = weight
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

        func canMoveTo(_ next: FallbackClaimExceptionStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
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
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == FallbackClaimExceptionStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackClaimExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback claim exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("fallback claim exception") \(code)"
        }

        func weightedExposure() -> Double {
            return ((budget + weight) * 100).rounded() / 100
        }

        func copyValue() -> FallbackClaimException {
            return FallbackClaimException(
                code: code,
                label: label,
                specialty: specialty,
                active: active,
                priority: priority,
                name: name,
                budget: budget,
                allergy: allergy,
                rate: rate,
                contactEmail: contactEmail,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback claim exception in status planned.
    static func newFallbackClaimException(_ code: String, label: String) -> FallbackClaimException {
        return FallbackClaimException(
            code: code,
            label: label,
            specialty: "",
            active: false,
            priority: 0,
            name: "",
            budget: 0.0,
            allergy: "",
            rate: 0.0,
            contactEmail: "",
            weight: 0.0,
            status: FallbackClaimExceptionStatus.planned
        )
    }
}
