import AcmePlatform
import Foundation

extension Labs {
    /// Where a lenient reference range draft is in its life cycle.
    enum LenientReferenceRangeDraftStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a lenient reference range draft and its current status.
    final class LenientReferenceRangeDraft {
        var code: String
        var title: String
        var summary: String
        var endsAt: Int
        var attempts: Int
        var status: LenientReferenceRangeDraftStatus

        init(code: String, title: String, summary: String, endsAt: Int, attempts: Int, status: LenientReferenceRangeDraftStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.endsAt = endsAt
            self.attempts = attempts
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

        func canMoveTo(_ next: LenientReferenceRangeDraftStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
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

        func moveTo(_ next: LenientReferenceRangeDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient reference range draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedExposure() -> Double {
            return ((Double(endsAt) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> LenientReferenceRangeDraft {
            return LenientReferenceRangeDraft(
                code: code,
                title: title,
                summary: summary,
                endsAt: endsAt,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient reference range draft in status created.
    static func newLenientReferenceRangeDraft(_ code: String, title: String) -> LenientReferenceRangeDraft {
        return LenientReferenceRangeDraft(
            code: code,
            title: title,
            summary: "",
            endsAt: 0,
            attempts: 0,
            status: LenientReferenceRangeDraftStatus.created
        )
    }
}
