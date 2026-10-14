import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched language bundle is in its life cycle.
    enum BatchedLanguageBundleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One batched language bundle, with what the planners need to act on it.
    final class BatchedLanguageBundle {
        var code: String
        var name: String
        var pinned: Bool
        var rate: Double
        var archived: Bool
        var allergy: String
        var status: BatchedLanguageBundleStatus

        init(code: String, name: String, pinned: Bool, rate: Double, archived: Bool, allergy: String, status: BatchedLanguageBundleStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.rate = rate
            self.archived = archived
            self.allergy = allergy
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedLanguageBundleStatus) -> Bool {
            switch status {
            case .requested:
                return next == BatchedLanguageBundleStatus.revoked
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: BatchedLanguageBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched language bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched language bundle") \(code)"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> BatchedLanguageBundle {
            return BatchedLanguageBundle(
                code: code,
                name: name,
                pinned: pinned,
                rate: rate,
                archived: archived,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched language bundle in status requested.
    static func newBatchedLanguageBundle(_ code: String, name: String) -> BatchedLanguageBundle {
        return BatchedLanguageBundle(
            code: code,
            name: name,
            pinned: false,
            rate: 0.0,
            archived: false,
            allergy: "",
            status: BatchedLanguageBundleStatus.requested
        )
    }
}
