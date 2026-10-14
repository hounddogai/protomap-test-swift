import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy inventory group is in its life cycle.
    enum LegacyInventoryGroupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One legacy inventory group, with what the planners need to act on it.
    final class LegacyInventoryGroup {
        var code: String
        var label: String
        var margin: Double
        var checksum: String
        var phone: String
        var version: Int
        var status: LegacyInventoryGroupStatus

        init(code: String, label: String, margin: Double, checksum: String, phone: String, version: Int, status: LegacyInventoryGroupStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.checksum = checksum
            self.phone = phone
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

        func canMoveTo(_ next: LegacyInventoryGroupStatus) -> Bool {
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
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == LegacyInventoryGroupStatus.completed || next == LegacyInventoryGroupStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: LegacyInventoryGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy inventory group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveTotal() -> Double {
            return ((margin + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyInventoryGroup {
            return LegacyInventoryGroup(
                code: code,
                label: label,
                margin: margin,
                checksum: checksum,
                phone: phone,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy inventory group in status planned.
    static func newLegacyInventoryGroup(_ code: String, label: String) -> LegacyInventoryGroup {
        return LegacyInventoryGroup(
            code: code,
            label: label,
            margin: 0.0,
            checksum: "",
            phone: "",
            version: 0,
            status: LegacyInventoryGroupStatus.planned
        )
    }
}
