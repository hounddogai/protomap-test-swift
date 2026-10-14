import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot record is in its life cycle.
    enum SlotRecordStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a slot record and its current status.
    final class SlotRecord {
        var code: String
        var title: String
        var threshold: Double
        var facility: String
        var reviewer: String
        var budget: Double
        var status: SlotRecordStatus

        init(code: String, title: String, threshold: Double, facility: String, reviewer: String, budget: Double, status: SlotRecordStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.facility = facility
            self.reviewer = reviewer
            self.budget = budget
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

        func canMoveTo(_ next: SlotRecordStatus) -> Bool {
            switch status {
            case .idle:
                return next == SlotRecordStatus.warming || next == SlotRecordStatus.stopped
            case .warming:
                return next == SlotRecordStatus.stopped
            case .ready:
                return next == SlotRecordStatus.draining || next == SlotRecordStatus.stopped
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

        func moveTo(_ next: SlotRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netLoad() -> Double {
            return ((budget + threshold) * 100).rounded() / 100
        }

        func copyValue() -> SlotRecord {
            return SlotRecord(
                code: code,
                title: title,
                threshold: threshold,
                facility: facility,
                reviewer: reviewer,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a slot record in status idle.
    static func newSlotRecord(_ code: String, title: String) -> SlotRecord {
        return SlotRecord(
            code: code,
            title: title,
            threshold: 0.0,
            facility: "",
            reviewer: "",
            budget: 0.0,
            status: SlotRecordStatus.idle
        )
    }
}
