import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range cycle is in its life cycle.
    enum ReferenceRangeCycleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A reference range cycle as the reference range team keeps it.
    final class ReferenceRangeCycle {
        var code: String
        var label: String
        var createdAt: Int
        var limit: Int
        var revision: Int
        var channel: String
        var segment: String
        var pinned: Bool
        var payer: String
        var status: ReferenceRangeCycleStatus

        init(code: String, label: String, createdAt: Int, limit: Int, revision: Int, channel: String, segment: String, pinned: Bool, payer: String, status: ReferenceRangeCycleStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.limit = limit
            self.revision = revision
            self.channel = channel
            self.segment = segment
            self.pinned = pinned
            self.payer = payer
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

        func canMoveTo(_ next: ReferenceRangeCycleStatus) -> Bool {
            switch status {
            case .draft:
                return next == ReferenceRangeCycleStatus.active || next == ReferenceRangeCycleStatus.suspended
            case .pending:
                return next == ReferenceRangeCycleStatus.suspended
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

        func moveTo(_ next: ReferenceRangeCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\("reference range cycle") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(createdAt) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeCycle {
            return ReferenceRangeCycle(
                code: code,
                label: label,
                createdAt: createdAt,
                limit: limit,
                revision: revision,
                channel: channel,
                segment: segment,
                pinned: pinned,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a reference range cycle in status draft.
    static func newReferenceRangeCycle(_ code: String, label: String) -> ReferenceRangeCycle {
        return ReferenceRangeCycle(
            code: code,
            label: label,
            createdAt: 0,
            limit: 0,
            revision: 0,
            channel: "",
            segment: "",
            pinned: false,
            payer: "",
            status: ReferenceRangeCycleStatus.draft
        )
    }
}
