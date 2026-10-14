import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement agreement is in its life cycle.
    enum StatementAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One statement agreement, with what the planners need to act on it.
    final class StatementAgreement {
        var code: String
        var name: String
        var payer: String
        var maximum: Double
        var encounterID: String
        var visible: Bool
        var bed: String
        var status: StatementAgreementStatus

        init(code: String, name: String, payer: String, maximum: Double, encounterID: String, visible: Bool, bed: String, status: StatementAgreementStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.maximum = maximum
            self.encounterID = encounterID
            self.visible = visible
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StatementAgreementStatus) -> Bool {
            switch status {
            case .draft:
                return next == StatementAgreementStatus.suspended || next == StatementAgreementStatus.closed
            case .pending:
                return next == StatementAgreementStatus.active || next == StatementAgreementStatus.suspended
            case .active:
                return next == StatementAgreementStatus.suspended || next == StatementAgreementStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: StatementAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("statement agreement") \(code)"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> StatementAgreement {
            return StatementAgreement(
                code: code,
                name: name,
                payer: payer,
                maximum: maximum,
                encounterID: encounterID,
                visible: visible,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a statement agreement in status draft.
    static func newStatementAgreement(_ code: String, name: String) -> StatementAgreement {
        return StatementAgreement(
            code: code,
            name: name,
            payer: "",
            maximum: 0.0,
            encounterID: "",
            visible: false,
            bed: "",
            status: StatementAgreementStatus.draft
        )
    }
}
