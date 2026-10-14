import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a rolling assessment reservation is in its life cycle.
    enum RollingAssessmentReservationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One rolling assessment reservation, with what the planners need to act on it.
    final class RollingAssessmentReservation {
        var code: String
        var name: String
        var amount: Double
        var cost: Double
        var title: String
        var quantity: Int
        var category: String
        var endsAt: Int
        var capacity: Int
        var description: String
        var status: RollingAssessmentReservationStatus

        init(code: String, name: String, amount: Double, cost: Double, title: String, quantity: Int, category: String, endsAt: Int, capacity: Int, description: String, status: RollingAssessmentReservationStatus) {
            self.code = code
            self.name = name
            self.amount = amount
            self.cost = cost
            self.title = title
            self.quantity = quantity
            self.category = category
            self.endsAt = endsAt
            self.capacity = capacity
            self.description = description
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

        func canMoveTo(_ next: RollingAssessmentReservationStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RollingAssessmentReservationStatus.approved || next == RollingAssessmentReservationStatus.rejected
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RollingAssessmentReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling assessment reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("rolling assessment reservation") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(quantity) + cost) * 100).rounded() / 100
        }

        func copyValue() -> RollingAssessmentReservation {
            return RollingAssessmentReservation(
                code: code,
                name: name,
                amount: amount,
                cost: cost,
                title: title,
                quantity: quantity,
                category: category,
                endsAt: endsAt,
                capacity: capacity,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a rolling assessment reservation in status proposed.
    static func newRollingAssessmentReservation(_ code: String, name: String) -> RollingAssessmentReservation {
        return RollingAssessmentReservation(
            code: code,
            name: name,
            amount: 0.0,
            cost: 0.0,
            title: "",
            quantity: 0,
            category: "",
            endsAt: 0,
            capacity: 0,
            description: "",
            status: RollingAssessmentReservationStatus.proposed
        )
    }
}
