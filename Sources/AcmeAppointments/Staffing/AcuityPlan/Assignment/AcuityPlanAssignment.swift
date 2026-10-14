import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan assignment is in its life cycle.
    enum AcuityPlanAssignmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a acuity plan assignment and its current status.
    final class AcuityPlanAssignment {
        var code: String
        var label: String
        var country: String
        var attempts: Int
        var priority: Int
        var rate: Double
        var ownerID: String
        var ratio: Double
        var retries: Int
        var windowDays: Int
        var currency: String
        var status: AcuityPlanAssignmentStatus

        init(code: String, label: String, country: String, attempts: Int, priority: Int, rate: Double, ownerID: String, ratio: Double, retries: Int, windowDays: Int, currency: String, status: AcuityPlanAssignmentStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.attempts = attempts
            self.priority = priority
            self.rate = rate
            self.ownerID = ownerID
            self.ratio = ratio
            self.retries = retries
            self.windowDays = windowDays
            self.currency = currency
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

        func canMoveTo(_ next: AcuityPlanAssignmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == AcuityPlanAssignmentStatus.revoked || next == AcuityPlanAssignmentStatus.expired
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

        func moveTo(_ next: AcuityPlanAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("acuity plan assignment") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(windowDays) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanAssignment {
            return AcuityPlanAssignment(
                code: code,
                label: label,
                country: country,
                attempts: attempts,
                priority: priority,
                rate: rate,
                ownerID: ownerID,
                ratio: ratio,
                retries: retries,
                windowDays: windowDays,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a acuity plan assignment in status requested.
    static func newAcuityPlanAssignment(_ code: String, label: String) -> AcuityPlanAssignment {
        return AcuityPlanAssignment(
            code: code,
            label: label,
            country: "",
            attempts: 0,
            priority: 0,
            rate: 0.0,
            ownerID: "",
            ratio: 0.0,
            retries: 0,
            windowDays: 0,
            currency: "",
            status: AcuityPlanAssignmentStatus.requested
        )
    }
}
