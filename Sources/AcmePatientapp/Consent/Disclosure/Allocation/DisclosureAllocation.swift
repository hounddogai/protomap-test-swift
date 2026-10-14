import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure allocation is in its life cycle.
    enum DisclosureAllocationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One disclosure allocation, with what the planners need to act on it.
    final class DisclosureAllocation {
        var code: String
        var label: String
        var version: Int
        var segment: String
        var procedureCode: String
        var quantity: Int
        var status: DisclosureAllocationStatus

        init(code: String, label: String, version: Int, segment: String, procedureCode: String, quantity: Int, status: DisclosureAllocationStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.segment = segment
            self.procedureCode = procedureCode
            self.quantity = quantity
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

        func canMoveTo(_ next: DisclosureAllocationStatus) -> Bool {
            switch status {
            case .planned:
                return next == DisclosureAllocationStatus.inProgress || next == DisclosureAllocationStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == DisclosureAllocationStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("disclosure allocation") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((Double(version) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureAllocation {
            return DisclosureAllocation(
                code: code,
                label: label,
                version: version,
                segment: segment,
                procedureCode: procedureCode,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a disclosure allocation in status planned.
    static func newDisclosureAllocation(_ code: String, label: String) -> DisclosureAllocation {
        return DisclosureAllocation(
            code: code,
            label: label,
            version: 0,
            segment: "",
            procedureCode: "",
            quantity: 0,
            status: DisclosureAllocationStatus.planned
        )
    }
}
