import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched denial checkpoint is in its life cycle.
    enum BatchedDenialCheckpointStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a batched denial checkpoint and its current status.
    final class BatchedDenialCheckpoint {
        var code: String
        var title: String
        var locale: String
        var country: String
        var windowDays: Int
        var source: String
        var status: BatchedDenialCheckpointStatus

        init(code: String, title: String, locale: String, country: String, windowDays: Int, source: String, status: BatchedDenialCheckpointStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.country = country
            self.windowDays = windowDays
            self.source = source
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

        func canMoveTo(_ next: BatchedDenialCheckpointStatus) -> Bool {
            switch status {
            case .draft:
                return next == BatchedDenialCheckpointStatus.active || next == BatchedDenialCheckpointStatus.closed
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: BatchedDenialCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched denial checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(windowDays)
        }

        func copyValue() -> BatchedDenialCheckpoint {
            return BatchedDenialCheckpoint(
                code: code,
                title: title,
                locale: locale,
                country: country,
                windowDays: windowDays,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a batched denial checkpoint in status draft.
    static func newBatchedDenialCheckpoint(_ code: String, title: String) -> BatchedDenialCheckpoint {
        return BatchedDenialCheckpoint(
            code: code,
            title: title,
            locale: "",
            country: "",
            windowDays: 0,
            source: "",
            status: BatchedDenialCheckpointStatus.draft
        )
    }
}
