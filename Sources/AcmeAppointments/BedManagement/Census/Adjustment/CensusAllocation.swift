import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census allocation is in its life cycle.
    enum CensusAllocationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A census allocation as the census team keeps it.
    final class CensusAllocation {
        var code: String
        var title: String
        var graceDays: Int
        var source: String
        var copay: Double
        var pinned: Bool
        var discount: Double
        var archived: Bool
        var windowDays: Int
        var locale: String
        var status: CensusAllocationStatus

        init(code: String, title: String, graceDays: Int, source: String, copay: Double, pinned: Bool, discount: Double, archived: Bool, windowDays: Int, locale: String, status: CensusAllocationStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.source = source
            self.copay = copay
            self.pinned = pinned
            self.discount = discount
            self.archived = archived
            self.windowDays = windowDays
            self.locale = locale
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

        func canMoveTo(_ next: CensusAllocationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == CensusAllocationStatus.inProgress || next == CensusAllocationStatus.completed
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == CensusAllocationStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("census allocation") \(code)"
        }

        func netTotal() -> Double {
            return ((copay - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> CensusAllocation {
            return CensusAllocation(
                code: code,
                title: title,
                graceDays: graceDays,
                source: source,
                copay: copay,
                pinned: pinned,
                discount: discount,
                archived: archived,
                windowDays: windowDays,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a census allocation in status planned.
    static func newCensusAllocation(_ code: String, title: String) -> CensusAllocation {
        return CensusAllocation(
            code: code,
            title: title,
            graceDays: 0,
            source: "",
            copay: 0.0,
            pinned: false,
            discount: 0.0,
            archived: false,
            windowDays: 0,
            locale: "",
            status: CensusAllocationStatus.planned
        )
    }
}
