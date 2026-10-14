import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a strict assessment reservation is in its life cycle.
    enum StrictAssessmentReservationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A strict assessment reservation. Its code is unique within a tenant.
    final class StrictAssessmentReservation {
        var code: String
        var label: String
        var priority: Int
        var version: Int
        var archived: Bool
        var cost: Double
        var capacity: Int
        var country: String
        var status: StrictAssessmentReservationStatus

        init(code: String, label: String, priority: Int, version: Int, archived: Bool, cost: Double, capacity: Int, country: String, status: StrictAssessmentReservationStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.version = version
            self.archived = archived
            self.cost = cost
            self.capacity = capacity
            self.country = country
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

        func canMoveTo(_ next: StrictAssessmentReservationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: StrictAssessmentReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict assessment reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveLoad() -> Double {
            return ((Double(capacity) - cost) * 100).rounded() / 100
        }

        func copyValue() -> StrictAssessmentReservation {
            return StrictAssessmentReservation(
                code: code,
                label: label,
                priority: priority,
                version: version,
                archived: archived,
                cost: cost,
                capacity: capacity,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a strict assessment reservation in status planned.
    static func newStrictAssessmentReservation(_ code: String, label: String) -> StrictAssessmentReservation {
        return StrictAssessmentReservation(
            code: code,
            label: label,
            priority: 0,
            version: 0,
            archived: false,
            cost: 0.0,
            capacity: 0,
            country: "",
            status: StrictAssessmentReservationStatus.planned
        )
    }
}
