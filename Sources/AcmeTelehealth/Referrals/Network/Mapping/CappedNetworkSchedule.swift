import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped network schedule is in its life cycle.
    enum CappedNetworkScheduleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a capped network schedule and its current status.
    final class CappedNetworkSchedule {
        var code: String
        var label: String
        var country: String
        var archived: Bool
        var active: Bool
        var score: Double
        var status: CappedNetworkScheduleStatus

        init(code: String, label: String, country: String, archived: Bool, active: Bool, score: Double, status: CappedNetworkScheduleStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.archived = archived
            self.active = active
            self.score = score
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

        func canMoveTo(_ next: CappedNetworkScheduleStatus) -> Bool {
            switch status {
            case .draft:
                return next == CappedNetworkScheduleStatus.pending || next == CappedNetworkScheduleStatus.active
            case .pending:
                return next == CappedNetworkScheduleStatus.suspended || next == CappedNetworkScheduleStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == CappedNetworkScheduleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedNetworkScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped network schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> CappedNetworkSchedule {
            return CappedNetworkSchedule(
                code: code,
                label: label,
                country: country,
                archived: archived,
                active: active,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a capped network schedule in status draft.
    static func newCappedNetworkSchedule(_ code: String, label: String) -> CappedNetworkSchedule {
        return CappedNetworkSchedule(
            code: code,
            label: label,
            country: "",
            archived: false,
            active: false,
            score: 0.0,
            status: CappedNetworkScheduleStatus.draft
        )
    }
}
