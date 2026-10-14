import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial budget is in its life cycle.
    enum DenialBudgetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A denial budget as the denial team keeps it.
    final class DenialBudget {
        var code: String
        var title: String
        var checksum: String
        var startsAt: Int
        var revision: Int
        var active: Bool
        var status: DenialBudgetStatus

        init(code: String, title: String, checksum: String, startsAt: Int, revision: Int, active: Bool, status: DenialBudgetStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.startsAt = startsAt
            self.revision = revision
            self.active = active
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

        func canMoveTo(_ next: DenialBudgetStatus) -> Bool {
            switch status {
            case .`open`:
                return next == DenialBudgetStatus.inReview || next == DenialBudgetStatus.reopened
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == DenialBudgetStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: DenialBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("denial budget") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((Double(revision) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> DenialBudget {
            return DenialBudget(
                code: code,
                title: title,
                checksum: checksum,
                startsAt: startsAt,
                revision: revision,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a denial budget in status open.
    static func newDenialBudget(_ code: String, title: String) -> DenialBudget {
        return DenialBudget(
            code: code,
            title: title,
            checksum: "",
            startsAt: 0,
            revision: 0,
            active: false,
            status: DenialBudgetStatus.`open`
        )
    }
}
