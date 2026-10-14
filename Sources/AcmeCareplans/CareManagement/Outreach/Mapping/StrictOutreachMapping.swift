import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a strict outreach mapping is in its life cycle.
    enum StrictOutreachMappingStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One strict outreach mapping, with what the planners need to act on it.
    final class StrictOutreachMapping {
        var code: String
        var label: String
        var discount: Double
        var checksum: String
        var priority: Int
        var segment: String
        var expiresAt: Int
        var status: StrictOutreachMappingStatus

        init(code: String, label: String, discount: Double, checksum: String, priority: Int, segment: String, expiresAt: Int, status: StrictOutreachMappingStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.checksum = checksum
            self.priority = priority
            self.segment = segment
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: StrictOutreachMappingStatus) -> Bool {
            switch status {
            case .planned:
                return next == StrictOutreachMappingStatus.scheduled
            case .scheduled:
                return next == StrictOutreachMappingStatus.completed || next == StrictOutreachMappingStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: StrictOutreachMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict outreach mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("strict outreach mapping") \(code)"
        }

        func netExposure() -> Double {
            return ((discount - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> StrictOutreachMapping {
            return StrictOutreachMapping(
                code: code,
                label: label,
                discount: discount,
                checksum: checksum,
                priority: priority,
                segment: segment,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a strict outreach mapping in status planned.
    static func newStrictOutreachMapping(_ code: String, label: String) -> StrictOutreachMapping {
        return StrictOutreachMapping(
            code: code,
            label: label,
            discount: 0.0,
            checksum: "",
            priority: 0,
            segment: "",
            expiresAt: 0,
            status: StrictOutreachMappingStatus.planned
        )
    }
}
