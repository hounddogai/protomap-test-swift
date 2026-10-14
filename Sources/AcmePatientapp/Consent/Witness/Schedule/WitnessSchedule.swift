import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness schedule is in its life cycle.
    enum WitnessScheduleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A witness schedule. Its code is unique within a tenant.
    final class WitnessSchedule {
        var code: String
        var title: String
        var updatedAt: Int
        var refills: Int
        var bed: String
        var pinned: Bool
        var locale: String
        var status: WitnessScheduleStatus

        init(code: String, title: String, updatedAt: Int, refills: Int, bed: String, pinned: Bool, locale: String, status: WitnessScheduleStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.refills = refills
            self.bed = bed
            self.pinned = pinned
            self.locale = locale
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

        func canMoveTo(_ next: WitnessScheduleStatus) -> Bool {
            switch status {
            case .new:
                return next == WitnessScheduleStatus.queued || next == WitnessScheduleStatus.failed
            case .queued:
                return next == WitnessScheduleStatus.running || next == WitnessScheduleStatus.failed
            case .running:
                return next == WitnessScheduleStatus.done || next == WitnessScheduleStatus.failed
            case .done:
                return next == WitnessScheduleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedTotal() -> Double {
            return (Double(refills) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> WitnessSchedule {
            return WitnessSchedule(
                code: code,
                title: title,
                updatedAt: updatedAt,
                refills: refills,
                bed: bed,
                pinned: pinned,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a witness schedule in status new.
    static func newWitnessSchedule(_ code: String, title: String) -> WitnessSchedule {
        return WitnessSchedule(
            code: code,
            title: title,
            updatedAt: 0,
            refills: 0,
            bed: "",
            pinned: false,
            locale: "",
            status: WitnessScheduleStatus.new
        )
    }
}
