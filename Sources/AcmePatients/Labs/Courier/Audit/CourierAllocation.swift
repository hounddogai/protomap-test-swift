import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier allocation is in its life cycle.
    enum CourierAllocationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a courier allocation and its current status.
    final class CourierAllocation {
        var code: String
        var title: String
        var contactEmail: String
        var segment: String
        var margin: Double
        var dosageMg: Double
        var status: CourierAllocationStatus

        init(code: String, title: String, contactEmail: String, segment: String, margin: Double, dosageMg: Double, status: CourierAllocationStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.segment = segment
            self.margin = margin
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: CourierAllocationStatus) -> Bool {
            switch status {
            case .created:
                return next == CourierAllocationStatus.validated || next == CourierAllocationStatus.published
            case .validated:
                return next == CourierAllocationStatus.published || next == CourierAllocationStatus.retired
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

        func moveTo(_ next: CourierAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("courier allocation") \(code)"
        }

        func netVolume() -> Double {
            return ((dosageMg - margin) * 100).rounded() / 100
        }

        func copyValue() -> CourierAllocation {
            return CourierAllocation(
                code: code,
                title: title,
                contactEmail: contactEmail,
                segment: segment,
                margin: margin,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a courier allocation in status created.
    static func newCourierAllocation(_ code: String, title: String) -> CourierAllocation {
        return CourierAllocation(
            code: code,
            title: title,
            contactEmail: "",
            segment: "",
            margin: 0.0,
            dosageMg: 0.0,
            status: CourierAllocationStatus.created
        )
    }
}
