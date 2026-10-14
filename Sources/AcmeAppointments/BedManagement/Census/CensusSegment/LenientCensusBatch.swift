import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient census batch is in its life cycle.
    enum LenientCensusBatchStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One lenient census batch, with what the planners need to act on it.
    final class LenientCensusBatch {
        var code: String
        var name: String
        var channel: String
        var currency: String
        var limit: Int
        var approved: Bool
        var status: LenientCensusBatchStatus

        init(code: String, name: String, channel: String, currency: String, limit: Int, approved: Bool, status: LenientCensusBatchStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.currency = currency
            self.limit = limit
            self.approved = approved
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

        func canMoveTo(_ next: LenientCensusBatchStatus) -> Bool {
            switch status {
            case .draft:
                return next == LenientCensusBatchStatus.pending || next == LenientCensusBatchStatus.suspended
            case .pending:
                return next == LenientCensusBatchStatus.suspended || next == LenientCensusBatchStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == LenientCensusBatchStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientCensusBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient census batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> LenientCensusBatch {
            return LenientCensusBatch(
                code: code,
                name: name,
                channel: channel,
                currency: currency,
                limit: limit,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a lenient census batch in status draft.
    static func newLenientCensusBatch(_ code: String, name: String) -> LenientCensusBatch {
        return LenientCensusBatch(
            code: code,
            name: name,
            channel: "",
            currency: "",
            limit: 0,
            approved: false,
            status: LenientCensusBatchStatus.draft
        )
    }
}
