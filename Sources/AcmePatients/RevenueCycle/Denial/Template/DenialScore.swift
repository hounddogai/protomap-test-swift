import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial score is in its life cycle.
    enum DenialScoreStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a denial score and its current status.
    final class DenialScore {
        var code: String
        var label: String
        var contactEmail: String
        var margin: Double
        var payer: String
        var status: DenialScoreStatus

        init(code: String, label: String, contactEmail: String, margin: Double, payer: String, status: DenialScoreStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.margin = margin
            self.payer = payer
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

        func canMoveTo(_ next: DenialScoreStatus) -> Bool {
            switch status {
            case .`open`:
                return next == DenialScoreStatus.reopened
            case .inReview:
                return next == DenialScoreStatus.reopened
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == DenialScoreStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DenialScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> DenialScore {
            return DenialScore(
                code: code,
                label: label,
                contactEmail: contactEmail,
                margin: margin,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a denial score in status open.
    static func newDenialScore(_ code: String, label: String) -> DenialScore {
        return DenialScore(
            code: code,
            label: label,
            contactEmail: "",
            margin: 0.0,
            payer: "",
            status: DenialScoreStatus.`open`
        )
    }
}
