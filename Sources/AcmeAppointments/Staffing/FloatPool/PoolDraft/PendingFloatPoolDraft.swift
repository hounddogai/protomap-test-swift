import AcmePlatform
import Foundation

extension Staffing {
    /// Where a pending float pool draft is in its life cycle.
    enum PendingFloatPoolDraftStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a pending float pool draft and its current status.
    final class PendingFloatPoolDraft {
        var code: String
        var name: String
        var margin: Double
        var ratio: Double
        var attempts: Int
        var status: PendingFloatPoolDraftStatus

        init(code: String, name: String, margin: Double, ratio: Double, attempts: Int, status: PendingFloatPoolDraftStatus) {
            self.code = code
            self.name = name
            self.margin = margin
            self.ratio = ratio
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingFloatPoolDraftStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PendingFloatPoolDraftStatus.approved
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: PendingFloatPoolDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending float pool draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedTotal() -> Double {
            return ((margin + ratio) * 100).rounded() / 100
        }

        func copyValue() -> PendingFloatPoolDraft {
            return PendingFloatPoolDraft(
                code: code,
                name: name,
                margin: margin,
                ratio: ratio,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending float pool draft in status proposed.
    static func newPendingFloatPoolDraft(_ code: String, name: String) -> PendingFloatPoolDraft {
        return PendingFloatPoolDraft(
            code: code,
            name: name,
            margin: 0.0,
            ratio: 0.0,
            attempts: 0,
            status: PendingFloatPoolDraftStatus.proposed
        )
    }
}
