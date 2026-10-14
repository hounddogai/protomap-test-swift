import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a capped bed board budget is in its life cycle.
    enum CappedBedBoardBudgetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A capped bed board budget. Its code is unique within a tenant.
    final class CappedBedBoardBudget {
        var code: String
        var label: String
        var visitMinutes: Int
        var checksum: String
        var ownerID: String
        var status: CappedBedBoardBudgetStatus

        init(code: String, label: String, visitMinutes: Int, checksum: String, ownerID: String, status: CappedBedBoardBudgetStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.checksum = checksum
            self.ownerID = ownerID
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

        func canMoveTo(_ next: CappedBedBoardBudgetStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == CappedBedBoardBudgetStatus.done
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: CappedBedBoardBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped bed board budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(visitMinutes)
        }

        func copyValue() -> CappedBedBoardBudget {
            return CappedBedBoardBudget(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                checksum: checksum,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped bed board budget in status new.
    static func newCappedBedBoardBudget(_ code: String, label: String) -> CappedBedBoardBudget {
        return CappedBedBoardBudget(
            code: code,
            label: label,
            visitMinutes: 0,
            checksum: "",
            ownerID: "",
            status: CappedBedBoardBudgetStatus.new
        )
    }
}
