import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched proxy slot is in its life cycle.
    enum BatchedProxySlotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A batched proxy slot. Its code is unique within a tenant.
    final class BatchedProxySlot {
        var code: String
        var label: String
        var country: String
        var approved: Bool
        var segment: String
        var visitMinutes: Int
        var description: String
        var amount: Double
        var minimum: Double
        var procedureCode: String
        var status: BatchedProxySlotStatus

        init(code: String, label: String, country: String, approved: Bool, segment: String, visitMinutes: Int, description: String, amount: Double, minimum: Double, procedureCode: String, status: BatchedProxySlotStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.approved = approved
            self.segment = segment
            self.visitMinutes = visitMinutes
            self.description = description
            self.amount = amount
            self.minimum = minimum
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: BatchedProxySlotStatus) -> Bool {
            switch status {
            case .proposed:
                return next == BatchedProxySlotStatus.withdrawn
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == BatchedProxySlotStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedProxySlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched proxy slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedTotal() -> Double {
            return ((minimum - amount) * 100).rounded() / 100
        }

        func copyValue() -> BatchedProxySlot {
            return BatchedProxySlot(
                code: code,
                label: label,
                country: country,
                approved: approved,
                segment: segment,
                visitMinutes: visitMinutes,
                description: description,
                amount: amount,
                minimum: minimum,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a batched proxy slot in status proposed.
    static func newBatchedProxySlot(_ code: String, label: String) -> BatchedProxySlot {
        return BatchedProxySlot(
            code: code,
            label: label,
            country: "",
            approved: false,
            segment: "",
            visitMinutes: 0,
            description: "",
            amount: 0.0,
            minimum: 0.0,
            procedureCode: "",
            status: BatchedProxySlotStatus.proposed
        )
    }
}
