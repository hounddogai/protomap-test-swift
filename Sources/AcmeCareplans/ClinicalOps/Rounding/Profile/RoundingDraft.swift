import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding draft is in its life cycle.
    enum RoundingDraftStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A rounding draft. Its code is unique within a tenant.
    final class RoundingDraft {
        var code: String
        var title: String
        var endsAt: Int
        var minimum: Double
        var tags: [String]
        var visitMinutes: Int
        var graceDays: Int
        var batchSize: Int
        var status: RoundingDraftStatus

        init(code: String, title: String, endsAt: Int, minimum: Double, tags: [String], visitMinutes: Int, graceDays: Int, batchSize: Int, status: RoundingDraftStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.minimum = minimum
            self.tags = tags
            self.visitMinutes = visitMinutes
            self.graceDays = graceDays
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RoundingDraftStatus) -> Bool {
            switch status {
            case .draft:
                return next == RoundingDraftStatus.closed
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == RoundingDraftStatus.suspended || next == RoundingDraftStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: RoundingDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveTotal() -> Double {
            return ((Double(endsAt) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RoundingDraft {
            return RoundingDraft(
                code: code,
                title: title,
                endsAt: endsAt,
                minimum: minimum,
                tags: tags,
                visitMinutes: visitMinutes,
                graceDays: graceDays,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rounding draft in status draft.
    static func newRoundingDraft(_ code: String, title: String) -> RoundingDraft {
        return RoundingDraft(
            code: code,
            title: title,
            endsAt: 0,
            minimum: 0.0,
            tags: [],
            visitMinutes: 0,
            graceDays: 0,
            batchSize: 0,
            status: RoundingDraftStatus.draft
        )
    }
}
