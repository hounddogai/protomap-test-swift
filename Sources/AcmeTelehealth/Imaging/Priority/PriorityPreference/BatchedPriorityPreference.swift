import AcmePlatform
import Foundation

extension Imaging {
    /// Where a batched priority preference is in its life cycle.
    enum BatchedPriorityPreferenceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One batched priority preference, with what the planners need to act on it.
    final class BatchedPriorityPreference {
        var code: String
        var name: String
        var capacity: Int
        var durationMinutes: Int
        var amount: Double
        var approved: Bool
        var copay: Double
        var refills: Int
        var windowDays: Int
        var ceiling: Double
        var status: BatchedPriorityPreferenceStatus

        init(code: String, name: String, capacity: Int, durationMinutes: Int, amount: Double, approved: Bool, copay: Double, refills: Int, windowDays: Int, ceiling: Double, status: BatchedPriorityPreferenceStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.durationMinutes = durationMinutes
            self.amount = amount
            self.approved = approved
            self.copay = copay
            self.refills = refills
            self.windowDays = windowDays
            self.ceiling = ceiling
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

        func canMoveTo(_ next: BatchedPriorityPreferenceStatus) -> Bool {
            switch status {
            case .proposed:
                return next == BatchedPriorityPreferenceStatus.withdrawn
            case .approved:
                return next == BatchedPriorityPreferenceStatus.rejected || next == BatchedPriorityPreferenceStatus.withdrawn
            case .rejected:
                return next == BatchedPriorityPreferenceStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedPriorityPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched priority preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netTotal() -> Double {
            return (ceiling * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> BatchedPriorityPreference {
            return BatchedPriorityPreference(
                code: code,
                name: name,
                capacity: capacity,
                durationMinutes: durationMinutes,
                amount: amount,
                approved: approved,
                copay: copay,
                refills: refills,
                windowDays: windowDays,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched priority preference in status proposed.
    static func newBatchedPriorityPreference(_ code: String, name: String) -> BatchedPriorityPreference {
        return BatchedPriorityPreference(
            code: code,
            name: name,
            capacity: 0,
            durationMinutes: 0,
            amount: 0.0,
            approved: false,
            copay: 0.0,
            refills: 0,
            windowDays: 0,
            ceiling: 0.0,
            status: BatchedPriorityPreferenceStatus.proposed
        )
    }
}
