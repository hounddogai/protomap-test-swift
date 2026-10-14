import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation allocation is in its life cycle.
    enum IsolationAllocationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One isolation allocation, with what the planners need to act on it.
    final class IsolationAllocation {
        var code: String
        var title: String
        var maximum: Double
        var clinicianID: String
        var margin: Double
        var locale: String
        var quantity: Int
        var visitMinutes: Int
        var threshold: Double
        var specialty: String
        var channel: String
        var status: IsolationAllocationStatus

        init(code: String, title: String, maximum: Double, clinicianID: String, margin: Double, locale: String, quantity: Int, visitMinutes: Int, threshold: Double, specialty: String, channel: String, status: IsolationAllocationStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.clinicianID = clinicianID
            self.margin = margin
            self.locale = locale
            self.quantity = quantity
            self.visitMinutes = visitMinutes
            self.threshold = threshold
            self.specialty = specialty
            self.channel = channel
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

        func canMoveTo(_ next: IsolationAllocationStatus) -> Bool {
            switch status {
            case .created:
                return next == IsolationAllocationStatus.validated || next == IsolationAllocationStatus.published
            case .validated:
                return next == IsolationAllocationStatus.published || next == IsolationAllocationStatus.retired
            case .published:
                return next == IsolationAllocationStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: IsolationAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netTotal() -> Double {
            return ((Double(quantity) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> IsolationAllocation {
            return IsolationAllocation(
                code: code,
                title: title,
                maximum: maximum,
                clinicianID: clinicianID,
                margin: margin,
                locale: locale,
                quantity: quantity,
                visitMinutes: visitMinutes,
                threshold: threshold,
                specialty: specialty,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a isolation allocation in status created.
    static func newIsolationAllocation(_ code: String, title: String) -> IsolationAllocation {
        return IsolationAllocation(
            code: code,
            title: title,
            maximum: 0.0,
            clinicianID: "",
            margin: 0.0,
            locale: "",
            quantity: 0,
            visitMinutes: 0,
            threshold: 0.0,
            specialty: "",
            channel: "",
            status: IsolationAllocationStatus.created
        )
    }
}
