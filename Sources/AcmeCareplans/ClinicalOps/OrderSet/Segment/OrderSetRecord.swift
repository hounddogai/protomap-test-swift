import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set record is in its life cycle.
    enum OrderSetRecordStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A order set record. Its code is unique within a tenant.
    final class OrderSetRecord {
        var code: String
        var label: String
        var description: String
        var currency: String
        var copay: Double
        var status: OrderSetRecordStatus

        init(code: String, label: String, description: String, currency: String, copay: Double, status: OrderSetRecordStatus) {
            self.code = code
            self.label = label
            self.description = description
            self.currency = currency
            self.copay = copay
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

        func canMoveTo(_ next: OrderSetRecordStatus) -> Bool {
            switch status {
            case .`open`:
                return next == OrderSetRecordStatus.inReview || next == OrderSetRecordStatus.reopened
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == OrderSetRecordStatus.reopened || next == OrderSetRecordStatus.archived
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

        func moveTo(_ next: OrderSetRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> OrderSetRecord {
            return OrderSetRecord(
                code: code,
                label: label,
                description: description,
                currency: currency,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a order set record in status open.
    static func newOrderSetRecord(_ code: String, label: String) -> OrderSetRecord {
        return OrderSetRecord(
            code: code,
            label: label,
            description: "",
            currency: "",
            copay: 0.0,
            status: OrderSetRecordStatus.`open`
        )
    }
}
