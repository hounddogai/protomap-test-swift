import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot audit is in its life cycle.
    enum SlotAuditStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One slot audit, with what the planners need to act on it.
    final class SlotAudit {
        var code: String
        var label: String
        var threshold: Double
        var timezone: String
        var title: String
        var approved: Bool
        var diagnosisCode: String
        var acuity: Int
        var quantity: Int
        var visible: Bool
        var procedureCode: String
        var status: SlotAuditStatus

        init(code: String, label: String, threshold: Double, timezone: String, title: String, approved: Bool, diagnosisCode: String, acuity: Int, quantity: Int, visible: Bool, procedureCode: String, status: SlotAuditStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.timezone = timezone
            self.title = title
            self.approved = approved
            self.diagnosisCode = diagnosisCode
            self.acuity = acuity
            self.quantity = quantity
            self.visible = visible
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: SlotAuditStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == SlotAuditStatus.suspended || next == SlotAuditStatus.closed
            case .active:
                return next == SlotAuditStatus.suspended
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

        func moveTo(_ next: SlotAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveLoad() -> Double {
            return ((Double(quantity) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> SlotAudit {
            return SlotAudit(
                code: code,
                label: label,
                threshold: threshold,
                timezone: timezone,
                title: title,
                approved: approved,
                diagnosisCode: diagnosisCode,
                acuity: acuity,
                quantity: quantity,
                visible: visible,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a slot audit in status draft.
    static func newSlotAudit(_ code: String, label: String) -> SlotAudit {
        return SlotAudit(
            code: code,
            label: label,
            threshold: 0.0,
            timezone: "",
            title: "",
            approved: false,
            diagnosisCode: "",
            acuity: 0,
            quantity: 0,
            visible: false,
            procedureCode: "",
            status: SlotAuditStatus.draft
        )
    }
}
