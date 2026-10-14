import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy audit is in its life cycle.
    enum ProxyAuditStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One proxy audit, with what the planners need to act on it.
    final class ProxyAudit {
        var code: String
        var title: String
        var procedureCode: String
        var sequence: Int
        var allergy: String
        var refills: Int
        var cost: Double
        var facility: String
        var discount: Double
        var retries: Int
        var status: ProxyAuditStatus

        init(code: String, title: String, procedureCode: String, sequence: Int, allergy: String, refills: Int, cost: Double, facility: String, discount: Double, retries: Int, status: ProxyAuditStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.sequence = sequence
            self.allergy = allergy
            self.refills = refills
            self.cost = cost
            self.facility = facility
            self.discount = discount
            self.retries = retries
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

        func canMoveTo(_ next: ProxyAuditStatus) -> Bool {
            switch status {
            case .planned:
                return next == ProxyAuditStatus.scheduled || next == ProxyAuditStatus.completed
            case .scheduled:
                return next == ProxyAuditStatus.inProgress || next == ProxyAuditStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ProxyAuditStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedExposure() -> Double {
            return (discount * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> ProxyAudit {
            return ProxyAudit(
                code: code,
                title: title,
                procedureCode: procedureCode,
                sequence: sequence,
                allergy: allergy,
                refills: refills,
                cost: cost,
                facility: facility,
                discount: discount,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a proxy audit in status planned.
    static func newProxyAudit(_ code: String, title: String) -> ProxyAudit {
        return ProxyAudit(
            code: code,
            title: title,
            procedureCode: "",
            sequence: 0,
            allergy: "",
            refills: 0,
            cost: 0.0,
            facility: "",
            discount: 0.0,
            retries: 0,
            status: ProxyAuditStatus.planned
        )
    }
}
