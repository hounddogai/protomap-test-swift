import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial schedule is in its life cycle.
    enum DenialScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a denial schedule and its current status.
    final class DenialSchedule {
        var code: String
        var name: String
        var payer: String
        var rate: Double
        var floorValue: Double
        var minimum: Double
        var revision: Int
        var ward: String
        var status: DenialScheduleStatus

        init(code: String, name: String, payer: String, rate: Double, floorValue: Double, minimum: Double, revision: Int, ward: String, status: DenialScheduleStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.rate = rate
            self.floorValue = floorValue
            self.minimum = minimum
            self.revision = revision
            self.ward = ward
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

        func canMoveTo(_ next: DenialScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == DenialScheduleStatus.resolved
            case .resolved:
                return next == DenialScheduleStatus.archived
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

        func moveTo(_ next: DenialScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("denial schedule") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((floorValue + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> DenialSchedule {
            return DenialSchedule(
                code: code,
                name: name,
                payer: payer,
                rate: rate,
                floorValue: floorValue,
                minimum: minimum,
                revision: revision,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a denial schedule in status open.
    static func newDenialSchedule(_ code: String, name: String) -> DenialSchedule {
        return DenialSchedule(
            code: code,
            name: name,
            payer: "",
            rate: 0.0,
            floorValue: 0.0,
            minimum: 0.0,
            revision: 0,
            ward: "",
            status: DenialScheduleStatus.`open`
        )
    }
}
