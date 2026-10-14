import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a batched order set exception is in its life cycle.
    enum BatchedOrderSetExceptionStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One batched order set exception, with what the planners need to act on it.
    final class BatchedOrderSetException {
        var code: String
        var name: String
        var maximum: Double
        var category: String
        var segment: String
        var discount: Double
        var facility: String
        var version: Int
        var attempts: Int
        var attributes: [String: String]
        var retries: Int
        var status: BatchedOrderSetExceptionStatus

        init(code: String, name: String, maximum: Double, category: String, segment: String, discount: Double, facility: String, version: Int, attempts: Int, attributes: [String: String], retries: Int, status: BatchedOrderSetExceptionStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.category = category
            self.segment = segment
            self.discount = discount
            self.facility = facility
            self.version = version
            self.attempts = attempts
            self.attributes = attributes
            self.retries = retries
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

        func canMoveTo(_ next: BatchedOrderSetExceptionStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
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
                return next == BatchedOrderSetExceptionStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedOrderSetExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched order set exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedTotal() -> Double {
            return ((Double(attempts) + discount) * 100).rounded() / 100
        }

        func copyValue() -> BatchedOrderSetException {
            return BatchedOrderSetException(
                code: code,
                name: name,
                maximum: maximum,
                category: category,
                segment: segment,
                discount: discount,
                facility: facility,
                version: version,
                attempts: attempts,
                attributes: attributes,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a batched order set exception in status proposed.
    static func newBatchedOrderSetException(_ code: String, name: String) -> BatchedOrderSetException {
        return BatchedOrderSetException(
            code: code,
            name: name,
            maximum: 0.0,
            category: "",
            segment: "",
            discount: 0.0,
            facility: "",
            version: 0,
            attempts: 0,
            attributes: [:],
            retries: 0,
            status: BatchedOrderSetExceptionStatus.proposed
        )
    }
}
