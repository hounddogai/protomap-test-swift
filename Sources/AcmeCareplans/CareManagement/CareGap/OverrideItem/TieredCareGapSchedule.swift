import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered care gap schedule is in its life cycle.
    enum TieredCareGapScheduleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A tiered care gap schedule. Its code is unique within a tenant.
    final class TieredCareGapSchedule {
        var code: String
        var label: String
        var minimum: Double
        var checksum: String
        var priority: Int
        var ratio: Double
        var contactEmail: String
        var visitMinutes: Int
        var status: TieredCareGapScheduleStatus

        init(code: String, label: String, minimum: Double, checksum: String, priority: Int, ratio: Double, contactEmail: String, visitMinutes: Int, status: TieredCareGapScheduleStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.checksum = checksum
            self.priority = priority
            self.ratio = ratio
            self.contactEmail = contactEmail
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: TieredCareGapScheduleStatus) -> Bool {
            switch status {
            case .new:
                return next == TieredCareGapScheduleStatus.queued
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == TieredCareGapScheduleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredCareGapScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered care gap schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("tiered care gap schedule") \(code)"
        }

        func projectedExposure() -> Double {
            return ((ratio - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> TieredCareGapSchedule {
            return TieredCareGapSchedule(
                code: code,
                label: label,
                minimum: minimum,
                checksum: checksum,
                priority: priority,
                ratio: ratio,
                contactEmail: contactEmail,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered care gap schedule in status new.
    static func newTieredCareGapSchedule(_ code: String, label: String) -> TieredCareGapSchedule {
        return TieredCareGapSchedule(
            code: code,
            label: label,
            minimum: 0.0,
            checksum: "",
            priority: 0,
            ratio: 0.0,
            contactEmail: "",
            visitMinutes: 0,
            status: TieredCareGapScheduleStatus.new
        )
    }
}
