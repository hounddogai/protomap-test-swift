import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending claim draft is in its life cycle.
    enum PendingClaimDraftStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a pending claim draft and its current status.
    final class PendingClaimDraft {
        var code: String
        var label: String
        var budget: Double
        var acuity: Int
        var dosageMg: Double
        var name: String
        var active: Bool
        var visitMinutes: Int
        var ratio: Double
        var copay: Double
        var status: PendingClaimDraftStatus

        init(code: String, label: String, budget: Double, acuity: Int, dosageMg: Double, name: String, active: Bool, visitMinutes: Int, ratio: Double, copay: Double, status: PendingClaimDraftStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.acuity = acuity
            self.dosageMg = dosageMg
            self.name = name
            self.active = active
            self.visitMinutes = visitMinutes
            self.ratio = ratio
            self.copay = copay
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

        func canMoveTo(_ next: PendingClaimDraftStatus) -> Bool {
            switch status {
            case .draft:
                return next == PendingClaimDraftStatus.suspended
            case .pending:
                return next == PendingClaimDraftStatus.suspended || next == PendingClaimDraftStatus.closed
            case .active:
                return next == PendingClaimDraftStatus.suspended
            case .suspended:
                return next == PendingClaimDraftStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingClaimDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending claim draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedTotal() -> Double {
            return ((dosageMg + copay) * 100).rounded() / 100
        }

        func copyValue() -> PendingClaimDraft {
            return PendingClaimDraft(
                code: code,
                label: label,
                budget: budget,
                acuity: acuity,
                dosageMg: dosageMg,
                name: name,
                active: active,
                visitMinutes: visitMinutes,
                ratio: ratio,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending claim draft in status draft.
    static func newPendingClaimDraft(_ code: String, label: String) -> PendingClaimDraft {
        return PendingClaimDraft(
            code: code,
            label: label,
            budget: 0.0,
            acuity: 0,
            dosageMg: 0.0,
            name: "",
            active: false,
            visitMinutes: 0,
            ratio: 0.0,
            copay: 0.0,
            status: PendingClaimDraftStatus.draft
        )
    }
}
