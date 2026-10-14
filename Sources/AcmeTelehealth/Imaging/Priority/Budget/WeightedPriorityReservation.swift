import AcmePlatform
import Foundation

extension Imaging {
    /// Where a weighted priority reservation is in its life cycle.
    enum WeightedPriorityReservationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A weighted priority reservation as the priority team keeps it.
    final class WeightedPriorityReservation {
        var code: String
        var label: String
        var bed: String
        var title: String
        var specialty: String
        var description: String
        var timezone: String
        var amount: Double
        var status: WeightedPriorityReservationStatus

        init(code: String, label: String, bed: String, title: String, specialty: String, description: String, timezone: String, amount: Double, status: WeightedPriorityReservationStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.title = title
            self.specialty = specialty
            self.description = description
            self.timezone = timezone
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedPriorityReservationStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == WeightedPriorityReservationStatus.resolved || next == WeightedPriorityReservationStatus.archived
            case .resolved:
                return next == WeightedPriorityReservationStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: WeightedPriorityReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted priority reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> WeightedPriorityReservation {
            return WeightedPriorityReservation(
                code: code,
                label: label,
                bed: bed,
                title: title,
                specialty: specialty,
                description: description,
                timezone: timezone,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted priority reservation in status open.
    static func newWeightedPriorityReservation(_ code: String, label: String) -> WeightedPriorityReservation {
        return WeightedPriorityReservation(
            code: code,
            label: label,
            bed: "",
            title: "",
            specialty: "",
            description: "",
            timezone: "",
            amount: 0.0,
            status: WeightedPriorityReservationStatus.`open`
        )
    }
}
