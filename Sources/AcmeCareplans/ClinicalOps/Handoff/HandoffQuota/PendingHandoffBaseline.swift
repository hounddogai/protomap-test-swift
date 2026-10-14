import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a pending handoff baseline is in its life cycle.
    enum PendingHandoffBaselineStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A pending handoff baseline. Its code is unique within a tenant.
    final class PendingHandoffBaseline {
        var code: String
        var title: String
        var ceiling: Double
        var priority: Int
        var category: String
        var durationMinutes: Int
        var diagnosisCode: String
        var ownerID: String
        var status: PendingHandoffBaselineStatus

        init(code: String, title: String, ceiling: Double, priority: Int, category: String, durationMinutes: Int, diagnosisCode: String, ownerID: String, status: PendingHandoffBaselineStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.priority = priority
            self.category = category
            self.durationMinutes = durationMinutes
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: PendingHandoffBaselineStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PendingHandoffBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending handoff baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending handoff baseline") \(code)"
        }

        func effectiveValue() -> Double {
            return ((Double(durationMinutes) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> PendingHandoffBaseline {
            return PendingHandoffBaseline(
                code: code,
                title: title,
                ceiling: ceiling,
                priority: priority,
                category: category,
                durationMinutes: durationMinutes,
                diagnosisCode: diagnosisCode,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a pending handoff baseline in status draft.
    static func newPendingHandoffBaseline(_ code: String, title: String) -> PendingHandoffBaseline {
        return PendingHandoffBaseline(
            code: code,
            title: title,
            ceiling: 0.0,
            priority: 0,
            category: "",
            durationMinutes: 0,
            diagnosisCode: "",
            ownerID: "",
            status: PendingHandoffBaselineStatus.draft
        )
    }
}
