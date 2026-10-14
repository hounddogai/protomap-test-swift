import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual census allocation is in its life cycle.
    enum ManualCensusAllocationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A manual census allocation. Its code is unique within a tenant.
    final class ManualCensusAllocation {
        var code: String
        var title: String
        var retries: Int
        var channel: String
        var windowDays: Int
        var weight: Double
        var reviewer: String
        var status: ManualCensusAllocationStatus

        init(code: String, title: String, retries: Int, channel: String, windowDays: Int, weight: Double, reviewer: String, status: ManualCensusAllocationStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.channel = channel
            self.windowDays = windowDays
            self.weight = weight
            self.reviewer = reviewer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualCensusAllocationStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ManualCensusAllocationStatus.active || next == ManualCensusAllocationStatus.closed
            case .active:
                return next == ManualCensusAllocationStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ManualCensusAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual census allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveTotal() -> Double {
            return (weight * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> ManualCensusAllocation {
            return ManualCensusAllocation(
                code: code,
                title: title,
                retries: retries,
                channel: channel,
                windowDays: windowDays,
                weight: weight,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a manual census allocation in status draft.
    static func newManualCensusAllocation(_ code: String, title: String) -> ManualCensusAllocation {
        return ManualCensusAllocation(
            code: code,
            title: title,
            retries: 0,
            channel: "",
            windowDays: 0,
            weight: 0.0,
            reviewer: "",
            status: ManualCensusAllocationStatus.draft
        )
    }
}
