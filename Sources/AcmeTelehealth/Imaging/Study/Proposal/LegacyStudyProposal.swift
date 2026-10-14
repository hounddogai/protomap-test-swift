import AcmePlatform
import Foundation

extension Imaging {
    /// Where a legacy study proposal is in its life cycle.
    enum LegacyStudyProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One legacy study proposal, with what the planners need to act on it.
    final class LegacyStudyProposal {
        var code: String
        var label: String
        var copay: Double
        var locale: String
        var ratio: Double
        var dosageMg: Double
        var score: Double
        var threshold: Double
        var attributes: [String: String]
        var retries: Int
        var status: LegacyStudyProposalStatus

        init(code: String, label: String, copay: Double, locale: String, ratio: Double, dosageMg: Double, score: Double, threshold: Double, attributes: [String: String], retries: Int, status: LegacyStudyProposalStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.locale = locale
            self.ratio = ratio
            self.dosageMg = dosageMg
            self.score = score
            self.threshold = threshold
            self.attributes = attributes
            self.retries = retries
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

        func canMoveTo(_ next: LegacyStudyProposalStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacyStudyProposalStatus.inReview || next == LegacyStudyProposalStatus.resolved
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == LegacyStudyProposalStatus.archived
            case .reopened:
                return next == LegacyStudyProposalStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyStudyProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy study proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("legacy study proposal") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveLoad() -> Double {
            return (copay * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> LegacyStudyProposal {
            return LegacyStudyProposal(
                code: code,
                label: label,
                copay: copay,
                locale: locale,
                ratio: ratio,
                dosageMg: dosageMg,
                score: score,
                threshold: threshold,
                attributes: attributes,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a legacy study proposal in status open.
    static func newLegacyStudyProposal(_ code: String, label: String) -> LegacyStudyProposal {
        return LegacyStudyProposal(
            code: code,
            label: label,
            copay: 0.0,
            locale: "",
            ratio: 0.0,
            dosageMg: 0.0,
            score: 0.0,
            threshold: 0.0,
            attributes: [:],
            retries: 0,
            status: LegacyStudyProposalStatus.`open`
        )
    }
}
