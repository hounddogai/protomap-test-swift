import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered outreach plan is in its life cycle.
    enum TieredOutreachPlanStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A tiered outreach plan. Its code is unique within a tenant.
    final class TieredOutreachPlan {
        var code: String
        var label: String
        var updatedAt: Int
        var revision: Int
        var procedureCode: String
        var status: TieredOutreachPlanStatus

        init(code: String, label: String, updatedAt: Int, revision: Int, procedureCode: String, status: TieredOutreachPlanStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.revision = revision
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

        func canMoveTo(_ next: TieredOutreachPlanStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == TieredOutreachPlanStatus.suspended
            case .suspended:
                return next == TieredOutreachPlanStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredOutreachPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered outreach plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\("tiered outreach plan") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(updatedAt) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> TieredOutreachPlan {
            return TieredOutreachPlan(
                code: code,
                label: label,
                updatedAt: updatedAt,
                revision: revision,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered outreach plan in status draft.
    static func newTieredOutreachPlan(_ code: String, label: String) -> TieredOutreachPlan {
        return TieredOutreachPlan(
            code: code,
            label: label,
            updatedAt: 0,
            revision: 0,
            procedureCode: "",
            status: TieredOutreachPlanStatus.draft
        )
    }
}
