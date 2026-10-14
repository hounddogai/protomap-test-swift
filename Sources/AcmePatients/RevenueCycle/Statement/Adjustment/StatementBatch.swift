import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement batch is in its life cycle.
    enum StatementBatchStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A statement batch. Its code is unique within a tenant.
    final class StatementBatch {
        var code: String
        var label: String
        var discount: Double
        var title: String
        var ward: String
        var status: StatementBatchStatus

        init(code: String, label: String, discount: Double, title: String, ward: String, status: StatementBatchStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.title = title
            self.ward = ward
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StatementBatchStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == StatementBatchStatus.published || next == StatementBatchStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: StatementBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("statement batch") \(code)"
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> StatementBatch {
            return StatementBatch(
                code: code,
                label: label,
                discount: discount,
                title: title,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a statement batch in status created.
    static func newStatementBatch(_ code: String, label: String) -> StatementBatch {
        return StatementBatch(
            code: code,
            label: label,
            discount: 0.0,
            title: "",
            ward: "",
            status: StatementBatchStatus.created
        )
    }
}
