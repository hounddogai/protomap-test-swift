import AcmePlatform
import Foundation

extension Consent {
    /// Where a fallback disclosure draft is in its life cycle.
    enum FallbackDisclosureDraftStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One fallback disclosure draft, with what the planners need to act on it.
    final class FallbackDisclosureDraft {
        var code: String
        var name: String
        var title: String
        var updatedAt: Int
        var payer: String
        var status: FallbackDisclosureDraftStatus

        init(code: String, name: String, title: String, updatedAt: Int, payer: String, status: FallbackDisclosureDraftStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.updatedAt = updatedAt
            self.payer = payer
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

        func canMoveTo(_ next: FallbackDisclosureDraftStatus) -> Bool {
            switch status {
            case .created:
                return next == FallbackDisclosureDraftStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == FallbackDisclosureDraftStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackDisclosureDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback disclosure draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> FallbackDisclosureDraft {
            return FallbackDisclosureDraft(
                code: code,
                name: name,
                title: title,
                updatedAt: updatedAt,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback disclosure draft in status created.
    static func newFallbackDisclosureDraft(_ code: String, name: String) -> FallbackDisclosureDraft {
        return FallbackDisclosureDraft(
            code: code,
            name: name,
            title: "",
            updatedAt: 0,
            payer: "",
            status: FallbackDisclosureDraftStatus.created
        )
    }
}
