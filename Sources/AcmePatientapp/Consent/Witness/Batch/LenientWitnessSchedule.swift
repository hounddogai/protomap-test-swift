import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient witness schedule is in its life cycle.
    enum LenientWitnessScheduleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a lenient witness schedule and its current status.
    final class LenientWitnessSchedule {
        var code: String
        var title: String
        var revision: Int
        var startsAt: Int
        var rate: Double
        var allergy: String
        var acuity: Int
        var status: LenientWitnessScheduleStatus

        init(code: String, title: String, revision: Int, startsAt: Int, rate: Double, allergy: String, acuity: Int, status: LenientWitnessScheduleStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.startsAt = startsAt
            self.rate = rate
            self.allergy = allergy
            self.acuity = acuity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientWitnessScheduleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == LenientWitnessScheduleStatus.rejected || next == LenientWitnessScheduleStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: LenientWitnessScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient witness schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("lenient witness schedule") \(code)"
        }

        func projectedVolume() -> Double {
            return (Double(revision) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> LenientWitnessSchedule {
            return LenientWitnessSchedule(
                code: code,
                title: title,
                revision: revision,
                startsAt: startsAt,
                rate: rate,
                allergy: allergy,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient witness schedule in status proposed.
    static func newLenientWitnessSchedule(_ code: String, title: String) -> LenientWitnessSchedule {
        return LenientWitnessSchedule(
            code: code,
            title: title,
            revision: 0,
            startsAt: 0,
            rate: 0.0,
            allergy: "",
            acuity: 0,
            status: LenientWitnessScheduleStatus.proposed
        )
    }
}
