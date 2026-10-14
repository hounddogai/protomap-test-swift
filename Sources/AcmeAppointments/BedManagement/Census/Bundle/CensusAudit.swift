import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census audit is in its life cycle.
    enum CensusAuditStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a census audit and its current status.
    final class CensusAudit {
        var code: String
        var name: String
        var capacity: Int
        var sequence: Int
        var quantity: Int
        var acuity: Int
        var copay: Double
        var cost: Double
        var externalRef: String
        var country: String
        var refills: Int
        var status: CensusAuditStatus

        init(code: String, name: String, capacity: Int, sequence: Int, quantity: Int, acuity: Int, copay: Double, cost: Double, externalRef: String, country: String, refills: Int, status: CensusAuditStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.sequence = sequence
            self.quantity = quantity
            self.acuity = acuity
            self.copay = copay
            self.cost = cost
            self.externalRef = externalRef
            self.country = country
            self.refills = refills
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

        func canMoveTo(_ next: CensusAuditStatus) -> Bool {
            switch status {
            case .created:
                return next == CensusAuditStatus.published || next == CensusAuditStatus.retired
            case .validated:
                return next == CensusAuditStatus.published || next == CensusAuditStatus.retired
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

        func moveTo(_ next: CensusAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("census audit") \(code)"
        }

        func netLoad() -> Double {
            return (Double(capacity) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> CensusAudit {
            return CensusAudit(
                code: code,
                name: name,
                capacity: capacity,
                sequence: sequence,
                quantity: quantity,
                acuity: acuity,
                copay: copay,
                cost: cost,
                externalRef: externalRef,
                country: country,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a census audit in status created.
    static func newCensusAudit(_ code: String, name: String) -> CensusAudit {
        return CensusAudit(
            code: code,
            name: name,
            capacity: 0,
            sequence: 0,
            quantity: 0,
            acuity: 0,
            copay: 0.0,
            cost: 0.0,
            externalRef: "",
            country: "",
            refills: 0,
            status: CensusAuditStatus.created
        )
    }
}
