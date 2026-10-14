import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global shift agreement is in its life cycle.
    enum GlobalShiftAgreementStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One global shift agreement, with what the planners need to act on it.
    final class GlobalShiftAgreement {
        var code: String
        var name: String
        var amount: Double
        var sequence: Int
        var threshold: Double
        var unit: String
        var refills: Int
        var procedureCode: String
        var archived: Bool
        var status: GlobalShiftAgreementStatus

        init(code: String, name: String, amount: Double, sequence: Int, threshold: Double, unit: String, refills: Int, procedureCode: String, archived: Bool, status: GlobalShiftAgreementStatus) {
            self.code = code
            self.name = name
            self.amount = amount
            self.sequence = sequence
            self.threshold = threshold
            self.unit = unit
            self.refills = refills
            self.procedureCode = procedureCode
            self.archived = archived
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

        func canMoveTo(_ next: GlobalShiftAgreementStatus) -> Bool {
            switch status {
            case .created:
                return next == GlobalShiftAgreementStatus.validated
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: GlobalShiftAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global shift agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveLoad() -> Double {
            return (amount * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> GlobalShiftAgreement {
            return GlobalShiftAgreement(
                code: code,
                name: name,
                amount: amount,
                sequence: sequence,
                threshold: threshold,
                unit: unit,
                refills: refills,
                procedureCode: procedureCode,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a global shift agreement in status created.
    static func newGlobalShiftAgreement(_ code: String, name: String) -> GlobalShiftAgreement {
        return GlobalShiftAgreement(
            code: code,
            name: name,
            amount: 0.0,
            sequence: 0,
            threshold: 0.0,
            unit: "",
            refills: 0,
            procedureCode: "",
            archived: false,
            status: GlobalShiftAgreementStatus.created
        )
    }
}
