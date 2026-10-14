import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool variance is in its life cycle.
    enum FloatPoolVarianceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A float pool variance as the float pool team keeps it.
    final class FloatPoolVariance {
        var code: String
        var label: String
        var reviewer: String
        var visible: Bool
        var archived: Bool
        var threshold: Double
        var notes: String
        var currency: String
        var encounterID: String
        var payer: String
        var capacity: Int
        var status: FloatPoolVarianceStatus

        init(code: String, label: String, reviewer: String, visible: Bool, archived: Bool, threshold: Double, notes: String, currency: String, encounterID: String, payer: String, capacity: Int, status: FloatPoolVarianceStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.visible = visible
            self.archived = archived
            self.threshold = threshold
            self.notes = notes
            self.currency = currency
            self.encounterID = encounterID
            self.payer = payer
            self.capacity = capacity
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

        func canMoveTo(_ next: FloatPoolVarianceStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == FloatPoolVarianceStatus.inProgress || next == FloatPoolVarianceStatus.completed
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == FloatPoolVarianceStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FloatPoolVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("float pool variance") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((threshold - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolVariance {
            return FloatPoolVariance(
                code: code,
                label: label,
                reviewer: reviewer,
                visible: visible,
                archived: archived,
                threshold: threshold,
                notes: notes,
                currency: currency,
                encounterID: encounterID,
                payer: payer,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a float pool variance in status planned.
    static func newFloatPoolVariance(_ code: String, label: String) -> FloatPoolVariance {
        return FloatPoolVariance(
            code: code,
            label: label,
            reviewer: "",
            visible: false,
            archived: false,
            threshold: 0.0,
            notes: "",
            currency: "",
            encounterID: "",
            payer: "",
            capacity: 0,
            status: FloatPoolVarianceStatus.planned
        )
    }
}
