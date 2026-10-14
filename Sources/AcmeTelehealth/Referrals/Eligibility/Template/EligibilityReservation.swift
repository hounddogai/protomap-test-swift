import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility reservation is in its life cycle.
    enum EligibilityReservationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A eligibility reservation as the eligibility team keeps it.
    final class EligibilityReservation {
        var code: String
        var name: String
        var country: String
        var maximum: Double
        var visitMinutes: Int
        var score: Double
        var version: Int
        var status: EligibilityReservationStatus

        init(code: String, name: String, country: String, maximum: Double, visitMinutes: Int, score: Double, version: Int, status: EligibilityReservationStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.maximum = maximum
            self.visitMinutes = visitMinutes
            self.score = score
            self.version = version
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

        func canMoveTo(_ next: EligibilityReservationStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == EligibilityReservationStatus.withdrawn
            case .rejected:
                return next == EligibilityReservationStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("eligibility reservation") \(code)"
        }

        func adjustedExposure() -> Double {
            return (Double(visitMinutes) * score * 100).rounded() / 100
        }

        func copyValue() -> EligibilityReservation {
            return EligibilityReservation(
                code: code,
                name: name,
                country: country,
                maximum: maximum,
                visitMinutes: visitMinutes,
                score: score,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a eligibility reservation in status proposed.
    static func newEligibilityReservation(_ code: String, name: String) -> EligibilityReservation {
        return EligibilityReservation(
            code: code,
            name: name,
            country: "",
            maximum: 0.0,
            visitMinutes: 0,
            score: 0.0,
            version: 0,
            status: EligibilityReservationStatus.proposed
        )
    }
}
