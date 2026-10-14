import AcmePlatform
import Foundation

extension Staffing {
    /// Where a scheduled shift reservation is in its life cycle.
    enum ScheduledShiftReservationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A scheduled shift reservation. Its code is unique within a tenant.
    final class ScheduledShiftReservation {
        var code: String
        var title: String
        var region: String
        var updatedAt: Int
        var encounterID: String
        var maximum: Double
        var acuity: Int
        var contactEmail: String
        var status: ScheduledShiftReservationStatus

        init(code: String, title: String, region: String, updatedAt: Int, encounterID: String, maximum: Double, acuity: Int, contactEmail: String, status: ScheduledShiftReservationStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.updatedAt = updatedAt
            self.encounterID = encounterID
            self.maximum = maximum
            self.acuity = acuity
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: ScheduledShiftReservationStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ScheduledShiftReservationStatus.published
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

        func moveTo(_ next: ScheduledShiftReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled shift reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedLoad() -> Double {
            return ((Double(acuity) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledShiftReservation {
            return ScheduledShiftReservation(
                code: code,
                title: title,
                region: region,
                updatedAt: updatedAt,
                encounterID: encounterID,
                maximum: maximum,
                acuity: acuity,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a scheduled shift reservation in status created.
    static func newScheduledShiftReservation(_ code: String, title: String) -> ScheduledShiftReservation {
        return ScheduledShiftReservation(
            code: code,
            title: title,
            region: "",
            updatedAt: 0,
            encounterID: "",
            maximum: 0.0,
            acuity: 0,
            contactEmail: "",
            status: ScheduledShiftReservationStatus.created
        )
    }
}
