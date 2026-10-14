import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score target is in its life cycle.
    enum RiskScoreTargetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One risk score target, with what the planners need to act on it.
    final class RiskScoreTarget {
        var code: String
        var label: String
        var name: String
        var currency: String
        var approved: Bool
        var patientRef: String
        var discount: Double
        var ownerID: String
        var status: RiskScoreTargetStatus

        init(code: String, label: String, name: String, currency: String, approved: Bool, patientRef: String, discount: Double, ownerID: String, status: RiskScoreTargetStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.currency = currency
            self.approved = approved
            self.patientRef = patientRef
            self.discount = discount
            self.ownerID = ownerID
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

        func canMoveTo(_ next: RiskScoreTargetStatus) -> Bool {
            switch status {
            case .draft:
                return next == RiskScoreTargetStatus.pending || next == RiskScoreTargetStatus.suspended
            case .pending:
                return next == RiskScoreTargetStatus.active || next == RiskScoreTargetStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == RiskScoreTargetStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RiskScoreTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> RiskScoreTarget {
            return RiskScoreTarget(
                code: code,
                label: label,
                name: name,
                currency: currency,
                approved: approved,
                patientRef: patientRef,
                discount: discount,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a risk score target in status draft.
    static func newRiskScoreTarget(_ code: String, label: String) -> RiskScoreTarget {
        return RiskScoreTarget(
            code: code,
            label: label,
            name: "",
            currency: "",
            approved: false,
            patientRef: "",
            discount: 0.0,
            ownerID: "",
            status: RiskScoreTargetStatus.draft
        )
    }
}
