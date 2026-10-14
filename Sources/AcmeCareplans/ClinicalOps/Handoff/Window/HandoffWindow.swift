import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff window is in its life cycle.
    enum HandoffWindowStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a handoff window and its current status.
    final class HandoffWindow {
        var code: String
        var label: String
        var retries: Int
        var ratio: Double
        var active: Bool
        var status: HandoffWindowStatus

        init(code: String, label: String, retries: Int, ratio: Double, active: Bool, status: HandoffWindowStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.ratio = ratio
            self.active = active
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: HandoffWindowStatus) -> Bool {
            switch status {
            case .idle:
                return next == HandoffWindowStatus.draining
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == HandoffWindowStatus.draining
            case .draining:
                return next == HandoffWindowStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: HandoffWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedTotal() -> Double {
            return ((Double(retries) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> HandoffWindow {
            return HandoffWindow(
                code: code,
                label: label,
                retries: retries,
                ratio: ratio,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a handoff window in status idle.
    static func newHandoffWindow(_ code: String, label: String) -> HandoffWindow {
        return HandoffWindow(
            code: code,
            label: label,
            retries: 0,
            ratio: 0.0,
            active: false,
            status: HandoffWindowStatus.idle
        )
    }
}
