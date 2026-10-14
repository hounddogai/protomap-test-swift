import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient bed board allocation is in its life cycle.
    enum LenientBedBoardAllocationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A lenient bed board allocation as the bed board team keeps it.
    final class LenientBedBoardAllocation {
        var code: String
        var label: String
        var priority: Int
        var country: String
        var batchSize: Int
        var approved: Bool
        var createdAt: Int
        var status: LenientBedBoardAllocationStatus

        init(code: String, label: String, priority: Int, country: String, batchSize: Int, approved: Bool, createdAt: Int, status: LenientBedBoardAllocationStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.country = country
            self.batchSize = batchSize
            self.approved = approved
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientBedBoardAllocationStatus) -> Bool {
            switch status {
            case .new:
                return next == LenientBedBoardAllocationStatus.queued || next == LenientBedBoardAllocationStatus.running
            case .queued:
                return next == LenientBedBoardAllocationStatus.running || next == LenientBedBoardAllocationStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == LenientBedBoardAllocationStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientBedBoardAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient bed board allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedTotal() -> Double {
            return ((Double(priority) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> LenientBedBoardAllocation {
            return LenientBedBoardAllocation(
                code: code,
                label: label,
                priority: priority,
                country: country,
                batchSize: batchSize,
                approved: approved,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a lenient bed board allocation in status new.
    static func newLenientBedBoardAllocation(_ code: String, label: String) -> LenientBedBoardAllocation {
        return LenientBedBoardAllocation(
            code: code,
            label: label,
            priority: 0,
            country: "",
            batchSize: 0,
            approved: false,
            createdAt: 0,
            status: LenientBedBoardAllocationStatus.new
        )
    }
}
