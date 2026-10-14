import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form audit is in its life cycle.
    enum ConsentFormAuditStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a consent form audit and its current status.
    final class ConsentFormAudit {
        var code: String
        var name: String
        var quantity: Int
        var cost: Double
        var capacity: Int
        var status: ConsentFormAuditStatus

        init(code: String, name: String, quantity: Int, cost: Double, capacity: Int, status: ConsentFormAuditStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.cost = cost
            self.capacity = capacity
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

        func canMoveTo(_ next: ConsentFormAuditStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ConsentFormAuditStatus.reopened || next == ConsentFormAuditStatus.archived
            case .reopened:
                return next == ConsentFormAuditStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("consent form audit") \(code)"
        }

        func weightedTotal() -> Double {
            return (Double(quantity) * cost * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormAudit {
            return ConsentFormAudit(
                code: code,
                name: name,
                quantity: quantity,
                cost: cost,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a consent form audit in status open.
    static func newConsentFormAudit(_ code: String, name: String) -> ConsentFormAudit {
        return ConsentFormAudit(
            code: code,
            name: name,
            quantity: 0,
            cost: 0.0,
            capacity: 0,
            status: ConsentFormAuditStatus.`open`
        )
    }
}
