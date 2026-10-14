import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled cleaning exception is in its life cycle.
    enum ScheduledCleaningExceptionStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One scheduled cleaning exception, with what the planners need to act on it.
    final class ScheduledCleaningException {
        var code: String
        var name: String
        var copay: Double
        var graceDays: Int
        var budget: Double
        var reviewer: String
        var bed: String
        var floorValue: Double
        var expiresAt: Int
        var currency: String
        var status: ScheduledCleaningExceptionStatus

        init(code: String, name: String, copay: Double, graceDays: Int, budget: Double, reviewer: String, bed: String, floorValue: Double, expiresAt: Int, currency: String, status: ScheduledCleaningExceptionStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.graceDays = graceDays
            self.budget = budget
            self.reviewer = reviewer
            self.bed = bed
            self.floorValue = floorValue
            self.expiresAt = expiresAt
            self.currency = currency
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledCleaningExceptionStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ScheduledCleaningExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled cleaning exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedLoad() -> Double {
            return ((copay - budget) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledCleaningException {
            return ScheduledCleaningException(
                code: code,
                name: name,
                copay: copay,
                graceDays: graceDays,
                budget: budget,
                reviewer: reviewer,
                bed: bed,
                floorValue: floorValue,
                expiresAt: expiresAt,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled cleaning exception in status created.
    static func newScheduledCleaningException(_ code: String, name: String) -> ScheduledCleaningException {
        return ScheduledCleaningException(
            code: code,
            name: name,
            copay: 0.0,
            graceDays: 0,
            budget: 0.0,
            reviewer: "",
            bed: "",
            floorValue: 0.0,
            expiresAt: 0,
            currency: "",
            status: ScheduledCleaningExceptionStatus.created
        )
    }
}
