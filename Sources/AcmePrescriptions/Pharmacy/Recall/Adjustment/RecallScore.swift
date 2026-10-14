import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall score is in its life cycle.
    enum RecallScoreStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a recall score and its current status.
    final class RecallScore {
        var code: String
        var label: String
        var currency: String
        var ratio: Double
        var payer: String
        var unit: String
        var status: RecallScoreStatus

        init(code: String, label: String, currency: String, ratio: Double, payer: String, unit: String, status: RecallScoreStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.ratio = ratio
            self.payer = payer
            self.unit = unit
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

        func canMoveTo(_ next: RecallScoreStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == RecallScoreStatus.resolved
            case .resolved:
                return next == RecallScoreStatus.reopened
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

        func moveTo(_ next: RecallScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("recall score") \(code)"
        }

        func measuredValue() -> Double {
            return ratio
        }

        func copyValue() -> RecallScore {
            return RecallScore(
                code: code,
                label: label,
                currency: currency,
                ratio: ratio,
                payer: payer,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a recall score in status open.
    static func newRecallScore(_ code: String, label: String) -> RecallScore {
        return RecallScore(
            code: code,
            label: label,
            currency: "",
            ratio: 0.0,
            payer: "",
            unit: "",
            status: RecallScoreStatus.`open`
        )
    }
}
