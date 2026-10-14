import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding entry is in its life cycle.
    enum RoundingEntryStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a rounding entry and its current status.
    final class RoundingEntry {
        var code: String
        var label: String
        var approved: Bool
        var acuity: Int
        var sequence: Int
        var amount: Double
        var segment: String
        var name: String
        var status: RoundingEntryStatus

        init(code: String, label: String, approved: Bool, acuity: Int, sequence: Int, amount: Double, segment: String, name: String, status: RoundingEntryStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.acuity = acuity
            self.sequence = sequence
            self.amount = amount
            self.segment = segment
            self.name = name
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RoundingEntryStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RoundingEntryStatus.resolved
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: RoundingEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("rounding entry") \(code)"
        }

        func projectedValue() -> Double {
            return (Double(acuity) * amount * 100).rounded() / 100
        }

        func copyValue() -> RoundingEntry {
            return RoundingEntry(
                code: code,
                label: label,
                approved: approved,
                acuity: acuity,
                sequence: sequence,
                amount: amount,
                segment: segment,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a rounding entry in status open.
    static func newRoundingEntry(_ code: String, label: String) -> RoundingEntry {
        return RoundingEntry(
            code: code,
            label: label,
            approved: false,
            acuity: 0,
            sequence: 0,
            amount: 0.0,
            segment: "",
            name: "",
            status: RoundingEntryStatus.`open`
        )
    }
}
