import AcmePlatform
import Foundation

extension Staffing {
    /// Where a pending skill mix preference is in its life cycle.
    enum PendingSkillMixPreferenceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a pending skill mix preference and its current status.
    final class PendingSkillMixPreference {
        var code: String
        var title: String
        var rate: Double
        var endsAt: Int
        var notes: String
        var copay: Double
        var visitMinutes: Int
        var facility: String
        var status: PendingSkillMixPreferenceStatus

        init(code: String, title: String, rate: Double, endsAt: Int, notes: String, copay: Double, visitMinutes: Int, facility: String, status: PendingSkillMixPreferenceStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.endsAt = endsAt
            self.notes = notes
            self.copay = copay
            self.visitMinutes = visitMinutes
            self.facility = facility
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingSkillMixPreferenceStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == PendingSkillMixPreferenceStatus.completed
            case .completed:
                return next == PendingSkillMixPreferenceStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingSkillMixPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending skill mix preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveVolume() -> Double {
            return (copay * rate * 100).rounded() / 100
        }

        func copyValue() -> PendingSkillMixPreference {
            return PendingSkillMixPreference(
                code: code,
                title: title,
                rate: rate,
                endsAt: endsAt,
                notes: notes,
                copay: copay,
                visitMinutes: visitMinutes,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a pending skill mix preference in status planned.
    static func newPendingSkillMixPreference(_ code: String, title: String) -> PendingSkillMixPreference {
        return PendingSkillMixPreference(
            code: code,
            title: title,
            rate: 0.0,
            endsAt: 0,
            notes: "",
            copay: 0.0,
            visitMinutes: 0,
            facility: "",
            status: PendingSkillMixPreferenceStatus.planned
        )
    }
}
