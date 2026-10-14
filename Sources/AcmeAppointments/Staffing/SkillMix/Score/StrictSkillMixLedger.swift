import AcmePlatform
import Foundation

extension Staffing {
    /// Where a strict skill mix ledger is in its life cycle.
    enum StrictSkillMixLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A strict skill mix ledger. Its code is unique within a tenant.
    final class StrictSkillMixLedger {
        var code: String
        var name: String
        var externalRef: String
        var quantity: Int
        var ratio: Double
        var ownerID: String
        var region: String
        var procedureCode: String
        var priority: Int
        var diagnosisCode: String
        var status: StrictSkillMixLedgerStatus

        init(code: String, name: String, externalRef: String, quantity: Int, ratio: Double, ownerID: String, region: String, procedureCode: String, priority: Int, diagnosisCode: String, status: StrictSkillMixLedgerStatus) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.quantity = quantity
            self.ratio = ratio
            self.ownerID = ownerID
            self.region = region
            self.procedureCode = procedureCode
            self.priority = priority
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: StrictSkillMixLedgerStatus) -> Bool {
            switch status {
            case .`open`:
                return next == StrictSkillMixLedgerStatus.resolved
            case .inReview:
                return next == StrictSkillMixLedgerStatus.reopened || next == StrictSkillMixLedgerStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == StrictSkillMixLedgerStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictSkillMixLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict skill mix ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict skill mix ledger") \(code)"
        }

        func weightedValue() -> Double {
            return (Double(priority) * ratio * 100).rounded() / 100
        }

        func copyValue() -> StrictSkillMixLedger {
            return StrictSkillMixLedger(
                code: code,
                name: name,
                externalRef: externalRef,
                quantity: quantity,
                ratio: ratio,
                ownerID: ownerID,
                region: region,
                procedureCode: procedureCode,
                priority: priority,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a strict skill mix ledger in status open.
    static func newStrictSkillMixLedger(_ code: String, name: String) -> StrictSkillMixLedger {
        return StrictSkillMixLedger(
            code: code,
            name: name,
            externalRef: "",
            quantity: 0,
            ratio: 0.0,
            ownerID: "",
            region: "",
            procedureCode: "",
            priority: 0,
            diagnosisCode: "",
            status: StrictSkillMixLedgerStatus.`open`
        )
    }
}
