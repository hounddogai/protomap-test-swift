import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation plan is in its life cycle.
    enum IsolationPlanStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A isolation plan as the isolation team keeps it.
    final class IsolationPlan {
        var code: String
        var label: String
        var pinned: Bool
        var limit: Int
        var encounterID: String
        var refills: Int
        var expiresAt: Int
        var summary: String
        var visible: Bool
        var startsAt: Int
        var status: IsolationPlanStatus

        init(code: String, label: String, pinned: Bool, limit: Int, encounterID: String, refills: Int, expiresAt: Int, summary: String, visible: Bool, startsAt: Int, status: IsolationPlanStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.limit = limit
            self.encounterID = encounterID
            self.refills = refills
            self.expiresAt = expiresAt
            self.summary = summary
            self.visible = visible
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: IsolationPlanStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == IsolationPlanStatus.running
            case .running:
                return next == IsolationPlanStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: IsolationPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("isolation plan") \(code)"
        }

        func effectiveLoad() -> Double {
            return (Double(startsAt) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> IsolationPlan {
            return IsolationPlan(
                code: code,
                label: label,
                pinned: pinned,
                limit: limit,
                encounterID: encounterID,
                refills: refills,
                expiresAt: expiresAt,
                summary: summary,
                visible: visible,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a isolation plan in status new.
    static func newIsolationPlan(_ code: String, label: String) -> IsolationPlan {
        return IsolationPlan(
            code: code,
            label: label,
            pinned: false,
            limit: 0,
            encounterID: "",
            refills: 0,
            expiresAt: 0,
            summary: "",
            visible: false,
            startsAt: 0,
            status: IsolationPlanStatus.new
        )
    }
}
