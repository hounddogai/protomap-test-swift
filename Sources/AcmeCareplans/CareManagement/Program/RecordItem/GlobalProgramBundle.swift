import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global program bundle is in its life cycle.
    enum GlobalProgramBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One global program bundle, with what the planners need to act on it.
    final class GlobalProgramBundle {
        var code: String
        var label: String
        var capacity: Int
        var ceiling: Double
        var region: String
        var status: GlobalProgramBundleStatus

        init(code: String, label: String, capacity: Int, ceiling: Double, region: String, status: GlobalProgramBundleStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.ceiling = ceiling
            self.region = region
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

        func canMoveTo(_ next: GlobalProgramBundleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == GlobalProgramBundleStatus.draining || next == GlobalProgramBundleStatus.stopped
            case .ready:
                return next == GlobalProgramBundleStatus.stopped
            case .draining:
                return next == GlobalProgramBundleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalProgramBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global program bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("global program bundle") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((ceiling + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalProgramBundle {
            return GlobalProgramBundle(
                code: code,
                label: label,
                capacity: capacity,
                ceiling: ceiling,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a global program bundle in status idle.
    static func newGlobalProgramBundle(_ code: String, label: String) -> GlobalProgramBundle {
        return GlobalProgramBundle(
            code: code,
            label: label,
            capacity: 0,
            ceiling: 0.0,
            region: "",
            status: GlobalProgramBundleStatus.idle
        )
    }
}
