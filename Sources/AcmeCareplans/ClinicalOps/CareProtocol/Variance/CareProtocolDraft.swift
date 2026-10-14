import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol draft is in its life cycle.
    enum CareProtocolDraftStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a care protocol draft and its current status.
    final class CareProtocolDraft {
        var code: String
        var name: String
        var ownerID: String
        var reviewer: String
        var locale: String
        var limit: Int
        var amount: Double
        var status: CareProtocolDraftStatus

        init(code: String, name: String, ownerID: String, reviewer: String, locale: String, limit: Int, amount: Double, status: CareProtocolDraftStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.reviewer = reviewer
            self.locale = locale
            self.limit = limit
            self.amount = amount
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

        func canMoveTo(_ next: CareProtocolDraftStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == CareProtocolDraftStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveLoad() -> Double {
            return (Double(limit) * amount * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolDraft {
            return CareProtocolDraft(
                code: code,
                name: name,
                ownerID: ownerID,
                reviewer: reviewer,
                locale: locale,
                limit: limit,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a care protocol draft in status open.
    static func newCareProtocolDraft(_ code: String, name: String) -> CareProtocolDraft {
        return CareProtocolDraft(
            code: code,
            name: name,
            ownerID: "",
            reviewer: "",
            locale: "",
            limit: 0,
            amount: 0.0,
            status: CareProtocolDraftStatus.`open`
        )
    }
}
