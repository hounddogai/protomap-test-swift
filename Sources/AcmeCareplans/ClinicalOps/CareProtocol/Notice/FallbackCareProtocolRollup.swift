import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback care protocol rollup is in its life cycle.
    enum FallbackCareProtocolRollupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One fallback care protocol rollup, with what the planners need to act on it.
    final class FallbackCareProtocolRollup {
        var code: String
        var title: String
        var retries: Int
        var minimum: Double
        var updatedAt: Int
        var status: FallbackCareProtocolRollupStatus

        init(code: String, title: String, retries: Int, minimum: Double, updatedAt: Int, status: FallbackCareProtocolRollupStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.minimum = minimum
            self.updatedAt = updatedAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackCareProtocolRollupStatus) -> Bool {
            switch status {
            case .new:
                return next == FallbackCareProtocolRollupStatus.running
            case .queued:
                return next == FallbackCareProtocolRollupStatus.running || next == FallbackCareProtocolRollupStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == FallbackCareProtocolRollupStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackCareProtocolRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback care protocol rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("fallback care protocol rollup") \(code)"
        }

        func projectedValue() -> Double {
            return (Double(retries) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> FallbackCareProtocolRollup {
            return FallbackCareProtocolRollup(
                code: code,
                title: title,
                retries: retries,
                minimum: minimum,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback care protocol rollup in status new.
    static func newFallbackCareProtocolRollup(_ code: String, title: String) -> FallbackCareProtocolRollup {
        return FallbackCareProtocolRollup(
            code: code,
            title: title,
            retries: 0,
            minimum: 0.0,
            updatedAt: 0,
            status: FallbackCareProtocolRollupStatus.new
        )
    }
}
