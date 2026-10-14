import AcmePlatform
import Foundation

extension Labs {
    /// Where a batched specimen budget is in its life cycle.
    enum BatchedSpecimenBudgetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One batched specimen budget, with what the planners need to act on it.
    final class BatchedSpecimenBudget {
        var code: String
        var title: String
        var encounterID: String
        var summary: String
        var acuity: Int
        var approved: Bool
        var version: Int
        var segment: String
        var status: BatchedSpecimenBudgetStatus

        init(code: String, title: String, encounterID: String, summary: String, acuity: Int, approved: Bool, version: Int, segment: String, status: BatchedSpecimenBudgetStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.summary = summary
            self.acuity = acuity
            self.approved = approved
            self.version = version
            self.segment = segment
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedSpecimenBudgetStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == BatchedSpecimenBudgetStatus.revoked
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: BatchedSpecimenBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched specimen budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("batched specimen budget") \(code)"
        }

        func adjustedValue() -> Double {
            return ((Double(version) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedSpecimenBudget {
            return BatchedSpecimenBudget(
                code: code,
                title: title,
                encounterID: encounterID,
                summary: summary,
                acuity: acuity,
                approved: approved,
                version: version,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a batched specimen budget in status requested.
    static func newBatchedSpecimenBudget(_ code: String, title: String) -> BatchedSpecimenBudget {
        return BatchedSpecimenBudget(
            code: code,
            title: title,
            encounterID: "",
            summary: "",
            acuity: 0,
            approved: false,
            version: 0,
            segment: "",
            status: BatchedSpecimenBudgetStatus.requested
        )
    }
}
