import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge reservation is in its life cycle.
    enum ChargeReservationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A charge reservation as the charge team keeps it.
    final class ChargeReservation {
        var code: String
        var title: String
        var procedureCode: String
        var limit: Int
        var acuity: Int
        var status: ChargeReservationStatus

        init(code: String, title: String, procedureCode: String, limit: Int, acuity: Int, status: ChargeReservationStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.limit = limit
            self.acuity = acuity
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

        func canMoveTo(_ next: ChargeReservationStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ChargeReservationStatus.archived
            case .reopened:
                return next == ChargeReservationStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("charge reservation") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(acuity) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> ChargeReservation {
            return ChargeReservation(
                code: code,
                title: title,
                procedureCode: procedureCode,
                limit: limit,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a charge reservation in status open.
    static func newChargeReservation(_ code: String, title: String) -> ChargeReservation {
        return ChargeReservation(
            code: code,
            title: title,
            procedureCode: "",
            limit: 0,
            acuity: 0,
            status: ChargeReservationStatus.`open`
        )
    }
}
