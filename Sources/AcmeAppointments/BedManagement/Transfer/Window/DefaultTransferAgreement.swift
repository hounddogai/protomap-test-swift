import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a default transfer agreement is in its life cycle.
    enum DefaultTransferAgreementStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a default transfer agreement and its current status.
    final class DefaultTransferAgreement {
        var code: String
        var title: String
        var source: String
        var maximum: Double
        var attributes: [String: String]
        var quantity: Int
        var status: DefaultTransferAgreementStatus

        init(code: String, title: String, source: String, maximum: Double, attributes: [String: String], quantity: Int, status: DefaultTransferAgreementStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.maximum = maximum
            self.attributes = attributes
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultTransferAgreementStatus) -> Bool {
            switch status {
            case .planned:
                return next == DefaultTransferAgreementStatus.completed || next == DefaultTransferAgreementStatus.cancelled
            case .scheduled:
                return next == DefaultTransferAgreementStatus.cancelled
            case .inProgress:
                return next == DefaultTransferAgreementStatus.completed || next == DefaultTransferAgreementStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: DefaultTransferAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default transfer agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
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

        func effectiveLoad() -> Double {
            return ((Double(quantity) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> DefaultTransferAgreement {
            return DefaultTransferAgreement(
                code: code,
                title: title,
                source: source,
                maximum: maximum,
                attributes: attributes,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a default transfer agreement in status planned.
    static func newDefaultTransferAgreement(_ code: String, title: String) -> DefaultTransferAgreement {
        return DefaultTransferAgreement(
            code: code,
            title: title,
            source: "",
            maximum: 0.0,
            attributes: [:],
            quantity: 0,
            status: DefaultTransferAgreementStatus.planned
        )
    }
}
