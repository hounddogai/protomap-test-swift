import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending recall rollup is in its life cycle.
    enum PendingRecallRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a pending recall rollup and its current status.
    final class PendingRecallRollup {
        var code: String
        var title: String
        var sequence: Int
        var durationMinutes: Int
        var locale: String
        var status: PendingRecallRollupStatus

        init(code: String, title: String, sequence: Int, durationMinutes: Int, locale: String, status: PendingRecallRollupStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.durationMinutes = durationMinutes
            self.locale = locale
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

        func canMoveTo(_ next: PendingRecallRollupStatus) -> Bool {
            switch status {
            case .draft:
                return next == PendingRecallRollupStatus.active
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PendingRecallRollupStatus.closed
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

        func moveTo(_ next: PendingRecallRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending recall rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedVolume() -> Double {
            return ((Double(durationMinutes) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> PendingRecallRollup {
            return PendingRecallRollup(
                code: code,
                title: title,
                sequence: sequence,
                durationMinutes: durationMinutes,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a pending recall rollup in status draft.
    static func newPendingRecallRollup(_ code: String, title: String) -> PendingRecallRollup {
        return PendingRecallRollup(
            code: code,
            title: title,
            sequence: 0,
            durationMinutes: 0,
            locale: "",
            status: PendingRecallRollupStatus.draft
        )
    }
}
