import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set request is in its life cycle.
    enum OrderSetRequestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A order set request as the order set team keeps it.
    final class OrderSetRequest {
        var code: String
        var label: String
        var ward: String
        var procedureCode: String
        var notes: String
        var amount: Double
        var status: OrderSetRequestStatus

        init(code: String, label: String, ward: String, procedureCode: String, notes: String, amount: Double, status: OrderSetRequestStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.procedureCode = procedureCode
            self.notes = notes
            self.amount = amount
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

        func canMoveTo(_ next: OrderSetRequestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == OrderSetRequestStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
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

        func moveTo(_ next: OrderSetRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("order set request") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> OrderSetRequest {
            return OrderSetRequest(
                code: code,
                label: label,
                ward: ward,
                procedureCode: procedureCode,
                notes: notes,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a order set request in status proposed.
    static func newOrderSetRequest(_ code: String, label: String) -> OrderSetRequest {
        return OrderSetRequest(
            code: code,
            label: label,
            ward: "",
            procedureCode: "",
            notes: "",
            amount: 0.0,
            status: OrderSetRequestStatus.proposed
        )
    }
}
