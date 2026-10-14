import AcmePlatform
import Foundation

extension Referrals {
    /// Where a pending follow up notice is in its life cycle.
    enum PendingFollowUpNoticeStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A pending follow up notice. Its code is unique within a tenant.
    final class PendingFollowUpNotice {
        var code: String
        var title: String
        var dosageMg: Double
        var active: Bool
        var description: String
        var diagnosisCode: String
        var status: PendingFollowUpNoticeStatus

        init(code: String, title: String, dosageMg: Double, active: Bool, description: String, diagnosisCode: String, status: PendingFollowUpNoticeStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.active = active
            self.description = description
            self.diagnosisCode = diagnosisCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingFollowUpNoticeStatus) -> Bool {
            switch status {
            case .idle:
                return next == PendingFollowUpNoticeStatus.draining || next == PendingFollowUpNoticeStatus.stopped
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: PendingFollowUpNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending follow up notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> PendingFollowUpNotice {
            return PendingFollowUpNotice(
                code: code,
                title: title,
                dosageMg: dosageMg,
                active: active,
                description: description,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending follow up notice in status idle.
    static func newPendingFollowUpNotice(_ code: String, title: String) -> PendingFollowUpNotice {
        return PendingFollowUpNotice(
            code: code,
            title: title,
            dosageMg: 0.0,
            active: false,
            description: "",
            diagnosisCode: "",
            status: PendingFollowUpNoticeStatus.idle
        )
    }
}
