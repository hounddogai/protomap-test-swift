import AcmePlatform
import Foundation

extension Imaging {
    /// Where a lenient worklist profile is in its life cycle.
    enum LenientWorklistProfileStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One lenient worklist profile, with what the planners need to act on it.
    final class LenientWorklistProfile {
        var code: String
        var label: String
        var currency: String
        var source: String
        var diagnosisCode: String
        var score: Double
        var status: LenientWorklistProfileStatus

        init(code: String, label: String, currency: String, source: String, diagnosisCode: String, score: Double, status: LenientWorklistProfileStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.source = source
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: LenientWorklistProfileStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == LenientWorklistProfileStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientWorklistProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient worklist profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> LenientWorklistProfile {
            return LenientWorklistProfile(
                code: code,
                label: label,
                currency: currency,
                source: source,
                diagnosisCode: diagnosisCode,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a lenient worklist profile in status created.
    static func newLenientWorklistProfile(_ code: String, label: String) -> LenientWorklistProfile {
        return LenientWorklistProfile(
            code: code,
            label: label,
            currency: "",
            source: "",
            diagnosisCode: "",
            score: 0.0,
            status: LenientWorklistProfileStatus.created
        )
    }
}
