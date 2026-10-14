import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a capped interaction baseline is in its life cycle.
    enum CappedInteractionBaselineStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A capped interaction baseline. Its code is unique within a tenant.
    final class CappedInteractionBaseline {
        var code: String
        var title: String
        var externalRef: String
        var pinned: Bool
        var revision: Int
        var status: CappedInteractionBaselineStatus

        init(code: String, title: String, externalRef: String, pinned: Bool, revision: Int, status: CappedInteractionBaselineStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.pinned = pinned
            self.revision = revision
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

        func canMoveTo(_ next: CappedInteractionBaselineStatus) -> Bool {
            switch status {
            case .new:
                return next == CappedInteractionBaselineStatus.queued || next == CappedInteractionBaselineStatus.done
            case .queued:
                return next == CappedInteractionBaselineStatus.running
            case .running:
                return next == CappedInteractionBaselineStatus.done || next == CappedInteractionBaselineStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: CappedInteractionBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped interaction baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> CappedInteractionBaseline {
            return CappedInteractionBaseline(
                code: code,
                title: title,
                externalRef: externalRef,
                pinned: pinned,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped interaction baseline in status new.
    static func newCappedInteractionBaseline(_ code: String, title: String) -> CappedInteractionBaseline {
        return CappedInteractionBaseline(
            code: code,
            title: title,
            externalRef: "",
            pinned: false,
            revision: 0,
            status: CappedInteractionBaselineStatus.new
        )
    }
}
