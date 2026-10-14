import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist budget is in its life cycle.
    enum WorklistBudgetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A worklist budget. Its code is unique within a tenant.
    final class WorklistBudget {
        var code: String
        var label: String
        var rate: Double
        var ownerID: String
        var graceDays: Int
        var refills: Int
        var updatedAt: Int
        var status: WorklistBudgetStatus

        init(code: String, label: String, rate: Double, ownerID: String, graceDays: Int, refills: Int, updatedAt: Int, status: WorklistBudgetStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.ownerID = ownerID
            self.graceDays = graceDays
            self.refills = refills
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: WorklistBudgetStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: WorklistBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveTotal() -> Double {
            return ((Double(graceDays) + rate) * 100).rounded() / 100
        }

        func copyValue() -> WorklistBudget {
            return WorklistBudget(
                code: code,
                label: label,
                rate: rate,
                ownerID: ownerID,
                graceDays: graceDays,
                refills: refills,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a worklist budget in status requested.
    static func newWorklistBudget(_ code: String, label: String) -> WorklistBudget {
        return WorklistBudget(
            code: code,
            label: label,
            rate: 0.0,
            ownerID: "",
            graceDays: 0,
            refills: 0,
            updatedAt: 0,
            status: WorklistBudgetStatus.requested
        )
    }
}
