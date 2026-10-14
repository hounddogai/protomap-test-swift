import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession allocation is in its life cycle.
    enum AccessionAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One accession allocation, with what the planners need to act on it.
    final class AccessionAllocation {
        var code: String
        var title: String
        var weight: Double
        var minimum: Double
        var rate: Double
        var label: String
        var category: String
        var attempts: Int
        var durationMinutes: Int
        var status: AccessionAllocationStatus

        init(code: String, title: String, weight: Double, minimum: Double, rate: Double, label: String, category: String, attempts: Int, durationMinutes: Int, status: AccessionAllocationStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.minimum = minimum
            self.rate = rate
            self.label = label
            self.category = category
            self.attempts = attempts
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: AccessionAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AccessionAllocationStatus.rejected || next == AccessionAllocationStatus.withdrawn
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: AccessionAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func projectedExposure() -> Double {
            return ((Double(attempts) - weight) * 100).rounded() / 100
        }

        func copyValue() -> AccessionAllocation {
            return AccessionAllocation(
                code: code,
                title: title,
                weight: weight,
                minimum: minimum,
                rate: rate,
                label: label,
                category: category,
                attempts: attempts,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a accession allocation in status proposed.
    static func newAccessionAllocation(_ code: String, title: String) -> AccessionAllocation {
        return AccessionAllocation(
            code: code,
            title: title,
            weight: 0.0,
            minimum: 0.0,
            rate: 0.0,
            label: "",
            category: "",
            attempts: 0,
            durationMinutes: 0,
            status: AccessionAllocationStatus.proposed
        )
    }
}
