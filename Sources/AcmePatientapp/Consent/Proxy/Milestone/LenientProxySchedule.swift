import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient proxy schedule is in its life cycle.
    enum LenientProxyScheduleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A lenient proxy schedule. Its code is unique within a tenant.
    final class LenientProxySchedule {
        var code: String
        var name: String
        var threshold: Double
        var allergy: String
        var retries: Int
        var durationMinutes: Int
        var timezone: String
        var cost: Double
        var minimum: Double
        var bed: String
        var status: LenientProxyScheduleStatus

        init(code: String, name: String, threshold: Double, allergy: String, retries: Int, durationMinutes: Int, timezone: String, cost: Double, minimum: Double, bed: String, status: LenientProxyScheduleStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.allergy = allergy
            self.retries = retries
            self.durationMinutes = durationMinutes
            self.timezone = timezone
            self.cost = cost
            self.minimum = minimum
            self.bed = bed
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

        func canMoveTo(_ next: LenientProxyScheduleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LenientProxyScheduleStatus.rejected || next == LenientProxyScheduleStatus.withdrawn
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == LenientProxyScheduleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientProxyScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient proxy schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedLoad() -> Double {
            return (cost * minimum * 100).rounded() / 100
        }

        func copyValue() -> LenientProxySchedule {
            return LenientProxySchedule(
                code: code,
                name: name,
                threshold: threshold,
                allergy: allergy,
                retries: retries,
                durationMinutes: durationMinutes,
                timezone: timezone,
                cost: cost,
                minimum: minimum,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a lenient proxy schedule in status proposed.
    static func newLenientProxySchedule(_ code: String, name: String) -> LenientProxySchedule {
        return LenientProxySchedule(
            code: code,
            name: name,
            threshold: 0.0,
            allergy: "",
            retries: 0,
            durationMinutes: 0,
            timezone: "",
            cost: 0.0,
            minimum: 0.0,
            bed: "",
            status: LenientProxyScheduleStatus.proposed
        )
    }
}
