import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier record is in its life cycle.
    enum CourierRecordStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A courier record. Its code is unique within a tenant.
    final class CourierRecord {
        var code: String
        var name: String
        var phone: String
        var contactEmail: String
        var locale: String
        var unit: String
        var ownerID: String
        var label: String
        var score: Double
        var status: CourierRecordStatus

        init(code: String, name: String, phone: String, contactEmail: String, locale: String, unit: String, ownerID: String, label: String, score: Double, status: CourierRecordStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.contactEmail = contactEmail
            self.locale = locale
            self.unit = unit
            self.ownerID = ownerID
            self.label = label
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CourierRecordStatus) -> Bool {
            switch status {
            case .idle:
                return next == CourierRecordStatus.warming || next == CourierRecordStatus.stopped
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == CourierRecordStatus.draining
            case .draining:
                return next == CourierRecordStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CourierRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("courier record") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> CourierRecord {
            return CourierRecord(
                code: code,
                name: name,
                phone: phone,
                contactEmail: contactEmail,
                locale: locale,
                unit: unit,
                ownerID: ownerID,
                label: label,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a courier record in status idle.
    static func newCourierRecord(_ code: String, name: String) -> CourierRecord {
        return CourierRecord(
            code: code,
            name: name,
            phone: "",
            contactEmail: "",
            locale: "",
            unit: "",
            ownerID: "",
            label: "",
            score: 0.0,
            status: CourierRecordStatus.idle
        )
    }
}
