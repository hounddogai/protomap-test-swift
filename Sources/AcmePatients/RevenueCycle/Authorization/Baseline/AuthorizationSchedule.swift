import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization schedule is in its life cycle.
    enum AuthorizationScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A authorization schedule. Its code is unique within a tenant.
    final class AuthorizationSchedule {
        var code: String
        var label: String
        var segment: String
        var ward: String
        var allergy: String
        var budget: Double
        var rate: Double
        var pinned: Bool
        var status: AuthorizationScheduleStatus

        init(code: String, label: String, segment: String, ward: String, allergy: String, budget: Double, rate: Double, pinned: Bool, status: AuthorizationScheduleStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.ward = ward
            self.allergy = allergy
            self.budget = budget
            self.rate = rate
            self.pinned = pinned
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AuthorizationScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AuthorizationScheduleStatus.inReview
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == AuthorizationScheduleStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: AuthorizationScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedTotal() -> Double {
            return ((rate - budget) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationSchedule {
            return AuthorizationSchedule(
                code: code,
                label: label,
                segment: segment,
                ward: ward,
                allergy: allergy,
                budget: budget,
                rate: rate,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a authorization schedule in status open.
    static func newAuthorizationSchedule(_ code: String, label: String) -> AuthorizationSchedule {
        return AuthorizationSchedule(
            code: code,
            label: label,
            segment: "",
            ward: "",
            allergy: "",
            budget: 0.0,
            rate: 0.0,
            pinned: false,
            status: AuthorizationScheduleStatus.`open`
        )
    }
}
