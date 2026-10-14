import AcmePlatform
import Foundation

extension Consent {
    /// Where a tiered proxy schedule is in its life cycle.
    enum TieredProxyScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One tiered proxy schedule, with what the planners need to act on it.
    final class TieredProxySchedule {
        var code: String
        var title: String
        var refills: Int
        var budget: Double
        var copay: Double
        var expiresAt: Int
        var score: Double
        var approved: Bool
        var visible: Bool
        var segment: String
        var currency: String
        var status: TieredProxyScheduleStatus

        init(code: String, title: String, refills: Int, budget: Double, copay: Double, expiresAt: Int, score: Double, approved: Bool, visible: Bool, segment: String, currency: String, status: TieredProxyScheduleStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.budget = budget
            self.copay = copay
            self.expiresAt = expiresAt
            self.score = score
            self.approved = approved
            self.visible = visible
            self.segment = segment
            self.currency = currency
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

        func canMoveTo(_ next: TieredProxyScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == TieredProxyScheduleStatus.reopened || next == TieredProxyScheduleStatus.archived
            case .reopened:
                return next == TieredProxyScheduleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredProxyScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered proxy schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netTotal() -> Double {
            return ((Double(expiresAt) - score) * 100).rounded() / 100
        }

        func copyValue() -> TieredProxySchedule {
            return TieredProxySchedule(
                code: code,
                title: title,
                refills: refills,
                budget: budget,
                copay: copay,
                expiresAt: expiresAt,
                score: score,
                approved: approved,
                visible: visible,
                segment: segment,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a tiered proxy schedule in status open.
    static func newTieredProxySchedule(_ code: String, title: String) -> TieredProxySchedule {
        return TieredProxySchedule(
            code: code,
            title: title,
            refills: 0,
            budget: 0.0,
            copay: 0.0,
            expiresAt: 0,
            score: 0.0,
            approved: false,
            visible: false,
            segment: "",
            currency: "",
            status: TieredProxyScheduleStatus.`open`
        )
    }
}
