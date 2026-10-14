import AcmePlatform
import Foundation

extension Imaging {
    /// Where a adaptive worklist draft is in its life cycle.
    enum AdaptiveWorklistDraftStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a adaptive worklist draft and its current status.
    final class AdaptiveWorklistDraft {
        var code: String
        var name: String
        var payer: String
        var currency: String
        var segment: String
        var score: Double
        var status: AdaptiveWorklistDraftStatus

        init(code: String, name: String, payer: String, currency: String, segment: String, score: Double, status: AdaptiveWorklistDraftStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.currency = currency
            self.segment = segment
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveWorklistDraftStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == AdaptiveWorklistDraftStatus.published || next == AdaptiveWorklistDraftStatus.retired
            case .published:
                return next == AdaptiveWorklistDraftStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveWorklistDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive worklist draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive worklist draft") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> AdaptiveWorklistDraft {
            return AdaptiveWorklistDraft(
                code: code,
                name: name,
                payer: payer,
                currency: currency,
                segment: segment,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a adaptive worklist draft in status created.
    static func newAdaptiveWorklistDraft(_ code: String, name: String) -> AdaptiveWorklistDraft {
        return AdaptiveWorklistDraft(
            code: code,
            name: name,
            payer: "",
            currency: "",
            segment: "",
            score: 0.0,
            status: AdaptiveWorklistDraftStatus.created
        )
    }
}
