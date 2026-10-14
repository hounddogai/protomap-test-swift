import AcmePlatform
import Foundation

extension Consent {
    /// Where a fallback witness draft is in its life cycle.
    enum FallbackWitnessDraftStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A fallback witness draft. Its code is unique within a tenant.
    final class FallbackWitnessDraft {
        var code: String
        var title: String
        var description: String
        var durationMinutes: Int
        var externalRef: String
        var startsAt: Int
        var threshold: Double
        var expiresAt: Int
        var status: FallbackWitnessDraftStatus

        init(code: String, title: String, description: String, durationMinutes: Int, externalRef: String, startsAt: Int, threshold: Double, expiresAt: Int, status: FallbackWitnessDraftStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.durationMinutes = durationMinutes
            self.externalRef = externalRef
            self.startsAt = startsAt
            self.threshold = threshold
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: FallbackWitnessDraftStatus) -> Bool {
            switch status {
            case .draft:
                return next == FallbackWitnessDraftStatus.active || next == FallbackWitnessDraftStatus.closed
            case .pending:
                return next == FallbackWitnessDraftStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: FallbackWitnessDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback witness draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedValue() -> Double {
            return ((Double(expiresAt) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> FallbackWitnessDraft {
            return FallbackWitnessDraft(
                code: code,
                title: title,
                description: description,
                durationMinutes: durationMinutes,
                externalRef: externalRef,
                startsAt: startsAt,
                threshold: threshold,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback witness draft in status draft.
    static func newFallbackWitnessDraft(_ code: String, title: String) -> FallbackWitnessDraft {
        return FallbackWitnessDraft(
            code: code,
            title: title,
            description: "",
            durationMinutes: 0,
            externalRef: "",
            startsAt: 0,
            threshold: 0.0,
            expiresAt: 0,
            status: FallbackWitnessDraftStatus.draft
        )
    }
}
