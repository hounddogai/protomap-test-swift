import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form schedule is in its life cycle.
    enum ConsentFormScheduleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A consent form schedule. Its code is unique within a tenant.
    final class ConsentFormSchedule {
        var code: String
        var title: String
        var locale: String
        var dosageMg: Double
        var capacity: Int
        var cost: Double
        var refills: Int
        var status: ConsentFormScheduleStatus

        init(code: String, title: String, locale: String, dosageMg: Double, capacity: Int, cost: Double, refills: Int, status: ConsentFormScheduleStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.dosageMg = dosageMg
            self.capacity = capacity
            self.cost = cost
            self.refills = refills
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

        func canMoveTo(_ next: ConsentFormScheduleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ConsentFormScheduleStatus.running
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ConsentFormScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("consent form schedule") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(capacity) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormSchedule {
            return ConsentFormSchedule(
                code: code,
                title: title,
                locale: locale,
                dosageMg: dosageMg,
                capacity: capacity,
                cost: cost,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a consent form schedule in status new.
    static func newConsentFormSchedule(_ code: String, title: String) -> ConsentFormSchedule {
        return ConsentFormSchedule(
            code: code,
            title: title,
            locale: "",
            dosageMg: 0.0,
            capacity: 0,
            cost: 0.0,
            refills: 0,
            status: ConsentFormScheduleStatus.new
        )
    }
}
