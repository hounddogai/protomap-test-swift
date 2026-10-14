import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a capped isolation schedule is in its life cycle.
    enum CappedIsolationScheduleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a capped isolation schedule and its current status.
    final class CappedIsolationSchedule {
        var code: String
        var name: String
        var graceDays: Int
        var locale: String
        var allergy: String
        var archived: Bool
        var channel: String
        var weight: Double
        var phone: String
        var ceiling: Double
        var facility: String
        var status: CappedIsolationScheduleStatus

        init(code: String, name: String, graceDays: Int, locale: String, allergy: String, archived: Bool, channel: String, weight: Double, phone: String, ceiling: Double, facility: String, status: CappedIsolationScheduleStatus) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.locale = locale
            self.allergy = allergy
            self.archived = archived
            self.channel = channel
            self.weight = weight
            self.phone = phone
            self.ceiling = ceiling
            self.facility = facility
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

        func canMoveTo(_ next: CappedIsolationScheduleStatus) -> Bool {
            switch status {
            case .new:
                return next == CappedIsolationScheduleStatus.done
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CappedIsolationScheduleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedIsolationScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped isolation schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped isolation schedule") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(graceDays) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> CappedIsolationSchedule {
            return CappedIsolationSchedule(
                code: code,
                name: name,
                graceDays: graceDays,
                locale: locale,
                allergy: allergy,
                archived: archived,
                channel: channel,
                weight: weight,
                phone: phone,
                ceiling: ceiling,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a capped isolation schedule in status new.
    static func newCappedIsolationSchedule(_ code: String, name: String) -> CappedIsolationSchedule {
        return CappedIsolationSchedule(
            code: code,
            name: name,
            graceDays: 0,
            locale: "",
            allergy: "",
            archived: false,
            channel: "",
            weight: 0.0,
            phone: "",
            ceiling: 0.0,
            facility: "",
            status: CappedIsolationScheduleStatus.new
        )
    }
}
