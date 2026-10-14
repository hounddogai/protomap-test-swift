import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a scheduled dispense agreement is in its life cycle.
    enum ScheduledDispenseAgreementStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A scheduled dispense agreement. Its code is unique within a tenant.
    final class ScheduledDispenseAgreement {
        var code: String
        var title: String
        var reviewer: String
        var durationMinutes: Int
        var startsAt: Int
        var allergy: String
        var status: ScheduledDispenseAgreementStatus

        init(code: String, title: String, reviewer: String, durationMinutes: Int, startsAt: Int, allergy: String, status: ScheduledDispenseAgreementStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.durationMinutes = durationMinutes
            self.startsAt = startsAt
            self.allergy = allergy
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

        func canMoveTo(_ next: ScheduledDispenseAgreementStatus) -> Bool {
            switch status {
            case .idle:
                return next == ScheduledDispenseAgreementStatus.draining
            case .warming:
                return next == ScheduledDispenseAgreementStatus.draining || next == ScheduledDispenseAgreementStatus.stopped
            case .ready:
                switch next {
                case .draining:
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

        func moveTo(_ next: ScheduledDispenseAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled dispense agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedLoad() -> Double {
            return (Double(durationMinutes) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledDispenseAgreement {
            return ScheduledDispenseAgreement(
                code: code,
                title: title,
                reviewer: reviewer,
                durationMinutes: durationMinutes,
                startsAt: startsAt,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled dispense agreement in status idle.
    static func newScheduledDispenseAgreement(_ code: String, title: String) -> ScheduledDispenseAgreement {
        return ScheduledDispenseAgreement(
            code: code,
            title: title,
            reviewer: "",
            durationMinutes: 0,
            startsAt: 0,
            allergy: "",
            status: ScheduledDispenseAgreementStatus.idle
        )
    }
}
