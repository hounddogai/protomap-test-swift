import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge schedule is in its life cycle.
    enum ChargeScheduleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A charge schedule as the charge team keeps it.
    final class ChargeSchedule {
        var code: String
        var name: String
        var notes: String
        var segment: String
        var threshold: Double
        var ceiling: Double
        var maximum: Double
        var externalRef: String
        var description: String
        var status: ChargeScheduleStatus

        init(code: String, name: String, notes: String, segment: String, threshold: Double, ceiling: Double, maximum: Double, externalRef: String, description: String, status: ChargeScheduleStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.segment = segment
            self.threshold = threshold
            self.ceiling = ceiling
            self.maximum = maximum
            self.externalRef = externalRef
            self.description = description
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

        func canMoveTo(_ next: ChargeScheduleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ChargeScheduleStatus.running || next == ChargeScheduleStatus.done
            case .running:
                return next == ChargeScheduleStatus.failed
            case .done:
                return next == ChargeScheduleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedExposure() -> Double {
            return (maximum * threshold * 100).rounded() / 100
        }

        func copyValue() -> ChargeSchedule {
            return ChargeSchedule(
                code: code,
                name: name,
                notes: notes,
                segment: segment,
                threshold: threshold,
                ceiling: ceiling,
                maximum: maximum,
                externalRef: externalRef,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a charge schedule in status new.
    static func newChargeSchedule(_ code: String, name: String) -> ChargeSchedule {
        return ChargeSchedule(
            code: code,
            name: name,
            notes: "",
            segment: "",
            threshold: 0.0,
            ceiling: 0.0,
            maximum: 0.0,
            externalRef: "",
            description: "",
            status: ChargeScheduleStatus.new
        )
    }
}
