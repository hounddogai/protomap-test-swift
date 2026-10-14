import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer draft is in its life cycle.
    enum TransferDraftStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A transfer draft as the transfer team keeps it.
    final class TransferDraft {
        var code: String
        var name: String
        var title: String
        var category: String
        var score: Double
        var status: TransferDraftStatus

        init(code: String, name: String, title: String, category: String, score: Double, status: TransferDraftStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.category = category
            self.score = score
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

        func canMoveTo(_ next: TransferDraftStatus) -> Bool {
            switch status {
            case .`open`:
                return next == TransferDraftStatus.reopened
            case .inReview:
                return next == TransferDraftStatus.resolved
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

        func moveTo(_ next: TransferDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> TransferDraft {
            return TransferDraft(
                code: code,
                name: name,
                title: title,
                category: category,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a transfer draft in status open.
    static func newTransferDraft(_ code: String, name: String) -> TransferDraft {
        return TransferDraft(
            code: code,
            name: name,
            title: "",
            category: "",
            score: 0.0,
            status: TransferDraftStatus.`open`
        )
    }
}
