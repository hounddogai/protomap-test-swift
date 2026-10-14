import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched disclosure tier is in its life cycle.
    enum BatchedDisclosureTierStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A batched disclosure tier as the disclosure team keeps it.
    final class BatchedDisclosureTier {
        var code: String
        var title: String
        var revision: Int
        var source: String
        var retries: Int
        var pinned: Bool
        var startsAt: Int
        var amount: Double
        var windowDays: Int
        var status: BatchedDisclosureTierStatus

        init(code: String, title: String, revision: Int, source: String, retries: Int, pinned: Bool, startsAt: Int, amount: Double, windowDays: Int, status: BatchedDisclosureTierStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.source = source
            self.retries = retries
            self.pinned = pinned
            self.startsAt = startsAt
            self.amount = amount
            self.windowDays = windowDays
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

        func canMoveTo(_ next: BatchedDisclosureTierStatus) -> Bool {
            switch status {
            case .draft:
                return next == BatchedDisclosureTierStatus.suspended || next == BatchedDisclosureTierStatus.closed
            case .pending:
                return next == BatchedDisclosureTierStatus.suspended
            case .active:
                switch next {
                case .suspended:
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

        func moveTo(_ next: BatchedDisclosureTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched disclosure tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedExposure() -> Double {
            return ((Double(startsAt) - amount) * 100).rounded() / 100
        }

        func copyValue() -> BatchedDisclosureTier {
            return BatchedDisclosureTier(
                code: code,
                title: title,
                revision: revision,
                source: source,
                retries: retries,
                pinned: pinned,
                startsAt: startsAt,
                amount: amount,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a batched disclosure tier in status draft.
    static func newBatchedDisclosureTier(_ code: String, title: String) -> BatchedDisclosureTier {
        return BatchedDisclosureTier(
            code: code,
            title: title,
            revision: 0,
            source: "",
            retries: 0,
            pinned: false,
            startsAt: 0,
            amount: 0.0,
            windowDays: 0,
            status: BatchedDisclosureTierStatus.draft
        )
    }
}
