import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled disclosure reservation is in its life cycle.
    enum ScheduledDisclosureReservationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One scheduled disclosure reservation, with what the planners need to act on it.
    final class ScheduledDisclosureReservation {
        var code: String
        var label: String
        var margin: Double
        var bed: String
        var name: String
        var capacity: Int
        var limit: Int
        var createdAt: Int
        var status: ScheduledDisclosureReservationStatus

        init(code: String, label: String, margin: Double, bed: String, name: String, capacity: Int, limit: Int, createdAt: Int, status: ScheduledDisclosureReservationStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.bed = bed
            self.name = name
            self.capacity = capacity
            self.limit = limit
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledDisclosureReservationStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ScheduledDisclosureReservationStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ScheduledDisclosureReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled disclosure reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedValue() -> Double {
            return ((Double(capacity) - margin) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledDisclosureReservation {
            return ScheduledDisclosureReservation(
                code: code,
                label: label,
                margin: margin,
                bed: bed,
                name: name,
                capacity: capacity,
                limit: limit,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled disclosure reservation in status proposed.
    static func newScheduledDisclosureReservation(_ code: String, label: String) -> ScheduledDisclosureReservation {
        return ScheduledDisclosureReservation(
            code: code,
            label: label,
            margin: 0.0,
            bed: "",
            name: "",
            capacity: 0,
            limit: 0,
            createdAt: 0,
            status: ScheduledDisclosureReservationStatus.proposed
        )
    }
}
