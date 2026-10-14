import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board allocation is in its life cycle.
    enum BedBoardAllocationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a bed board allocation and its current status.
    final class BedBoardAllocation {
        var code: String
        var label: String
        var segment: String
        var durationMinutes: Int
        var pinned: Bool
        var payer: String
        var diagnosisCode: String
        var archived: Bool
        var channel: String
        var reviewer: String
        var status: BedBoardAllocationStatus

        init(code: String, label: String, segment: String, durationMinutes: Int, pinned: Bool, payer: String, diagnosisCode: String, archived: Bool, channel: String, reviewer: String, status: BedBoardAllocationStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.durationMinutes = durationMinutes
            self.pinned = pinned
            self.payer = payer
            self.diagnosisCode = diagnosisCode
            self.archived = archived
            self.channel = channel
            self.reviewer = reviewer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BedBoardAllocationStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == BedBoardAllocationStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: BedBoardAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return Double(durationMinutes)
        }

        func copyValue() -> BedBoardAllocation {
            return BedBoardAllocation(
                code: code,
                label: label,
                segment: segment,
                durationMinutes: durationMinutes,
                pinned: pinned,
                payer: payer,
                diagnosisCode: diagnosisCode,
                archived: archived,
                channel: channel,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a bed board allocation in status idle.
    static func newBedBoardAllocation(_ code: String, label: String) -> BedBoardAllocation {
        return BedBoardAllocation(
            code: code,
            label: label,
            segment: "",
            durationMinutes: 0,
            pinned: false,
            payer: "",
            diagnosisCode: "",
            archived: false,
            channel: "",
            reviewer: "",
            status: BedBoardAllocationStatus.idle
        )
    }
}
