import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness override is in its life cycle.
    enum WitnessOverrideStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A witness override as the witness team keeps it.
    final class WitnessOverride {
        var code: String
        var title: String
        var segment: String
        var pinned: Bool
        var ward: String
        var graceDays: Int
        var status: WitnessOverrideStatus

        init(code: String, title: String, segment: String, pinned: Bool, ward: String, graceDays: Int, status: WitnessOverrideStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.pinned = pinned
            self.ward = ward
            self.graceDays = graceDays
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

        func canMoveTo(_ next: WitnessOverrideStatus) -> Bool {
            switch status {
            case .new:
                return next == WitnessOverrideStatus.queued || next == WitnessOverrideStatus.done
            case .queued:
                return next == WitnessOverrideStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: WitnessOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> WitnessOverride {
            return WitnessOverride(
                code: code,
                title: title,
                segment: segment,
                pinned: pinned,
                ward: ward,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a witness override in status new.
    static func newWitnessOverride(_ code: String, title: String) -> WitnessOverride {
        return WitnessOverride(
            code: code,
            title: title,
            segment: "",
            pinned: false,
            ward: "",
            graceDays: 0,
            status: WitnessOverrideStatus.new
        )
    }
}
