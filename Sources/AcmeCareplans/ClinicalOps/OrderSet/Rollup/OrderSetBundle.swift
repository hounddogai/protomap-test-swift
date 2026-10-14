import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set bundle is in its life cycle.
    enum OrderSetBundleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A order set bundle as the order set team keeps it.
    final class OrderSetBundle {
        var code: String
        var title: String
        var approved: Bool
        var patientRef: String
        var name: String
        var externalRef: String
        var quantity: Int
        var floorValue: Double
        var contactEmail: String
        var attempts: Int
        var status: OrderSetBundleStatus

        init(code: String, title: String, approved: Bool, patientRef: String, name: String, externalRef: String, quantity: Int, floorValue: Double, contactEmail: String, attempts: Int, status: OrderSetBundleStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.patientRef = patientRef
            self.name = name
            self.externalRef = externalRef
            self.quantity = quantity
            self.floorValue = floorValue
            self.contactEmail = contactEmail
            self.attempts = attempts
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

        func canMoveTo(_ next: OrderSetBundleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == OrderSetBundleStatus.rejected
            case .approved:
                return next == OrderSetBundleStatus.rejected || next == OrderSetBundleStatus.withdrawn
            case .rejected:
                return next == OrderSetBundleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OrderSetBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveExposure() -> Double {
            return (floorValue * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetBundle {
            return OrderSetBundle(
                code: code,
                title: title,
                approved: approved,
                patientRef: patientRef,
                name: name,
                externalRef: externalRef,
                quantity: quantity,
                floorValue: floorValue,
                contactEmail: contactEmail,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a order set bundle in status proposed.
    static func newOrderSetBundle(_ code: String, title: String) -> OrderSetBundle {
        return OrderSetBundle(
            code: code,
            title: title,
            approved: false,
            patientRef: "",
            name: "",
            externalRef: "",
            quantity: 0,
            floorValue: 0.0,
            contactEmail: "",
            attempts: 0,
            status: OrderSetBundleStatus.proposed
        )
    }
}
