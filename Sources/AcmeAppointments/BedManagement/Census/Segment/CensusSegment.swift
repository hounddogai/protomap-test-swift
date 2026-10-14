import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census segment is in its life cycle.
    enum CensusSegmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a census segment and its current status.
    final class CensusSegment {
        var code: String
        var label: String
        var refills: Int
        var ward: String
        var score: Double
        var amount: Double
        var notes: String
        var segment: String
        var status: CensusSegmentStatus

        init(code: String, label: String, refills: Int, ward: String, score: Double, amount: Double, notes: String, segment: String, status: CensusSegmentStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.ward = ward
            self.score = score
            self.amount = amount
            self.notes = notes
            self.segment = segment
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

        func canMoveTo(_ next: CensusSegmentStatus) -> Bool {
            switch status {
            case .planned:
                return next == CensusSegmentStatus.scheduled || next == CensusSegmentStatus.cancelled
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == CensusSegmentStatus.completed
            case .completed:
                return next == CensusSegmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedLoad() -> Double {
            return ((score - amount) * 100).rounded() / 100
        }

        func copyValue() -> CensusSegment {
            return CensusSegment(
                code: code,
                label: label,
                refills: refills,
                ward: ward,
                score: score,
                amount: amount,
                notes: notes,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a census segment in status planned.
    static func newCensusSegment(_ code: String, label: String) -> CensusSegment {
        return CensusSegment(
            code: code,
            label: label,
            refills: 0,
            ward: "",
            score: 0.0,
            amount: 0.0,
            notes: "",
            segment: "",
            status: CensusSegmentStatus.planned
        )
    }
}
