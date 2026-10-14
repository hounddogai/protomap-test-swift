import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a adaptive rounding draft is in its life cycle.
    enum AdaptiveRoundingDraftStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One adaptive rounding draft, with what the planners need to act on it.
    final class AdaptiveRoundingDraft {
        var code: String
        var label: String
        var score: Double
        var archived: Bool
        var sequence: Int
        var minimum: Double
        var updatedAt: Int
        var summary: String
        var status: AdaptiveRoundingDraftStatus

        init(code: String, label: String, score: Double, archived: Bool, sequence: Int, minimum: Double, updatedAt: Int, summary: String, status: AdaptiveRoundingDraftStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.archived = archived
            self.sequence = sequence
            self.minimum = minimum
            self.updatedAt = updatedAt
            self.summary = summary
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

        func canMoveTo(_ next: AdaptiveRoundingDraftStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == AdaptiveRoundingDraftStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveRoundingDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive rounding draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netValue() -> Double {
            return ((Double(updatedAt) - score) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveRoundingDraft {
            return AdaptiveRoundingDraft(
                code: code,
                label: label,
                score: score,
                archived: archived,
                sequence: sequence,
                minimum: minimum,
                updatedAt: updatedAt,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive rounding draft in status created.
    static func newAdaptiveRoundingDraft(_ code: String, label: String) -> AdaptiveRoundingDraft {
        return AdaptiveRoundingDraft(
            code: code,
            label: label,
            score: 0.0,
            archived: false,
            sequence: 0,
            minimum: 0.0,
            updatedAt: 0,
            summary: "",
            status: AdaptiveRoundingDraftStatus.created
        )
    }
}
