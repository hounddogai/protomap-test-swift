import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary discharge plan baseline is in its life cycle.
    enum PrimaryDischargePlanBaselineStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One primary discharge plan baseline, with what the planners need to act on it.
    final class PrimaryDischargePlanBaseline {
        var code: String
        var title: String
        var quantity: Int
        var name: String
        var capacity: Int
        var phone: String
        var patientRef: String
        var status: PrimaryDischargePlanBaselineStatus

        init(code: String, title: String, quantity: Int, name: String, capacity: Int, phone: String, patientRef: String, status: PrimaryDischargePlanBaselineStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.name = name
            self.capacity = capacity
            self.phone = phone
            self.patientRef = patientRef
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

        func canMoveTo(_ next: PrimaryDischargePlanBaselineStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PrimaryDischargePlanBaselineStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryDischargePlanBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary discharge plan baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedVolume() -> Double {
            return (Double(quantity) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryDischargePlanBaseline {
            return PrimaryDischargePlanBaseline(
                code: code,
                title: title,
                quantity: quantity,
                name: name,
                capacity: capacity,
                phone: phone,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary discharge plan baseline in status proposed.
    static func newPrimaryDischargePlanBaseline(_ code: String, title: String) -> PrimaryDischargePlanBaseline {
        return PrimaryDischargePlanBaseline(
            code: code,
            title: title,
            quantity: 0,
            name: "",
            capacity: 0,
            phone: "",
            patientRef: "",
            status: PrimaryDischargePlanBaselineStatus.proposed
        )
    }
}
