import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a scheduled alert schedule is in its life cycle.
    enum ScheduledAlertScheduleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A scheduled alert schedule as the alert team keeps it.
    final class ScheduledAlertSchedule {
        var code: String
        var title: String
        var dosageMg: Double
        var quantity: Int
        var ratio: Double
        var checksum: String
        var procedureCode: String
        var discount: Double
        var unit: String
        var status: ScheduledAlertScheduleStatus

        init(code: String, title: String, dosageMg: Double, quantity: Int, ratio: Double, checksum: String, procedureCode: String, discount: Double, unit: String, status: ScheduledAlertScheduleStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.quantity = quantity
            self.ratio = ratio
            self.checksum = checksum
            self.procedureCode = procedureCode
            self.discount = discount
            self.unit = unit
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

        func canMoveTo(_ next: ScheduledAlertScheduleStatus) -> Bool {
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
                switch next {
                case .running:
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
                return next == ScheduledAlertScheduleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledAlertScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled alert schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netVolume() -> Double {
            return ((Double(quantity) + discount) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledAlertSchedule {
            return ScheduledAlertSchedule(
                code: code,
                title: title,
                dosageMg: dosageMg,
                quantity: quantity,
                ratio: ratio,
                checksum: checksum,
                procedureCode: procedureCode,
                discount: discount,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a scheduled alert schedule in status new.
    static func newScheduledAlertSchedule(_ code: String, title: String) -> ScheduledAlertSchedule {
        return ScheduledAlertSchedule(
            code: code,
            title: title,
            dosageMg: 0.0,
            quantity: 0,
            ratio: 0.0,
            checksum: "",
            procedureCode: "",
            discount: 0.0,
            unit: "",
            status: ScheduledAlertScheduleStatus.new
        )
    }
}
