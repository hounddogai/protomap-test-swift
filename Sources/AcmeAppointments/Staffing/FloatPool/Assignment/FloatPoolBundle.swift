import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool bundle is in its life cycle.
    enum FloatPoolBundleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A float pool bundle. Its code is unique within a tenant.
    final class FloatPoolBundle {
        var code: String
        var label: String
        var ratio: Double
        var ownerID: String
        var version: Int
        var status: FloatPoolBundleStatus

        init(code: String, label: String, ratio: Double, ownerID: String, version: Int, status: FloatPoolBundleStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.ownerID = ownerID
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FloatPoolBundleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == FloatPoolBundleStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == FloatPoolBundleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FloatPoolBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("float pool bundle") \(code)"
        }

        func netExposure() -> Double {
            return (Double(version) * ratio * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolBundle {
            return FloatPoolBundle(
                code: code,
                label: label,
                ratio: ratio,
                ownerID: ownerID,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a float pool bundle in status planned.
    static func newFloatPoolBundle(_ code: String, label: String) -> FloatPoolBundle {
        return FloatPoolBundle(
            code: code,
            label: label,
            ratio: 0.0,
            ownerID: "",
            version: 0,
            status: FloatPoolBundleStatus.planned
        )
    }
}
