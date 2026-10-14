import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim draft is in its life cycle.
    enum ClaimDraftStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A claim draft as the claim team keeps it.
    final class ClaimDraft {
        var code: String
        var title: String
        var category: String
        var acuity: Int
        var score: Double
        var floorValue: Double
        var status: ClaimDraftStatus

        init(code: String, title: String, category: String, acuity: Int, score: Double, floorValue: Double, status: ClaimDraftStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.acuity = acuity
            self.score = score
            self.floorValue = floorValue
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

        func canMoveTo(_ next: ClaimDraftStatus) -> Bool {
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
                return next == ClaimDraftStatus.published || next == ClaimDraftStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ClaimDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("claim draft") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((Double(acuity) + score) * 100).rounded() / 100
        }

        func copyValue() -> ClaimDraft {
            return ClaimDraft(
                code: code,
                title: title,
                category: category,
                acuity: acuity,
                score: score,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a claim draft in status created.
    static func newClaimDraft(_ code: String, title: String) -> ClaimDraft {
        return ClaimDraft(
            code: code,
            title: title,
            category: "",
            acuity: 0,
            score: 0.0,
            floorValue: 0.0,
            status: ClaimDraftStatus.created
        )
    }
}
