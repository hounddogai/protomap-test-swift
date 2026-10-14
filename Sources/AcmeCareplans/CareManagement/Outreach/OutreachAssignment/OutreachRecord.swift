import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach record is in its life cycle.
    enum OutreachRecordStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A outreach record. Its code is unique within a tenant.
    final class OutreachRecord {
        var code: String
        var name: String
        var discount: Double
        var patientRef: String
        var budget: Double
        var locale: String
        var unit: String
        var visible: Bool
        var maximum: Double
        var checksum: String
        var status: OutreachRecordStatus

        init(code: String, name: String, discount: Double, patientRef: String, budget: Double, locale: String, unit: String, visible: Bool, maximum: Double, checksum: String, status: OutreachRecordStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.patientRef = patientRef
            self.budget = budget
            self.locale = locale
            self.unit = unit
            self.visible = visible
            self.maximum = maximum
            self.checksum = checksum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OutreachRecordStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == OutreachRecordStatus.inProgress
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == OutreachRecordStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OutreachRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedLoad() -> Double {
            return ((maximum + budget) * 100).rounded() / 100
        }

        func copyValue() -> OutreachRecord {
            return OutreachRecord(
                code: code,
                name: name,
                discount: discount,
                patientRef: patientRef,
                budget: budget,
                locale: locale,
                unit: unit,
                visible: visible,
                maximum: maximum,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a outreach record in status planned.
    static func newOutreachRecord(_ code: String, name: String) -> OutreachRecord {
        return OutreachRecord(
            code: code,
            name: name,
            discount: 0.0,
            patientRef: "",
            budget: 0.0,
            locale: "",
            unit: "",
            visible: false,
            maximum: 0.0,
            checksum: "",
            status: OutreachRecordStatus.planned
        )
    }
}
