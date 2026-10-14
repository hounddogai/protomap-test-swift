import AcmePlatform
import Foundation

extension Referrals {
    /// Where a global slot notice is in its life cycle.
    enum GlobalSlotNoticeStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One global slot notice, with what the planners need to act on it.
    final class GlobalSlotNotice {
        var code: String
        var title: String
        var region: String
        var capacity: Int
        var timezone: String
        var sequence: Int
        var acuity: Int
        var summary: String
        var status: GlobalSlotNoticeStatus

        init(code: String, title: String, region: String, capacity: Int, timezone: String, sequence: Int, acuity: Int, summary: String, status: GlobalSlotNoticeStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.capacity = capacity
            self.timezone = timezone
            self.sequence = sequence
            self.acuity = acuity
            self.summary = summary
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

        func canMoveTo(_ next: GlobalSlotNoticeStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == GlobalSlotNoticeStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == GlobalSlotNoticeStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalSlotNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global slot notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveExposure() -> Double {
            return ((Double(sequence) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalSlotNotice {
            return GlobalSlotNotice(
                code: code,
                title: title,
                region: region,
                capacity: capacity,
                timezone: timezone,
                sequence: sequence,
                acuity: acuity,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a global slot notice in status new.
    static func newGlobalSlotNotice(_ code: String, title: String) -> GlobalSlotNotice {
        return GlobalSlotNotice(
            code: code,
            title: title,
            region: "",
            capacity: 0,
            timezone: "",
            sequence: 0,
            acuity: 0,
            summary: "",
            status: GlobalSlotNoticeStatus.new
        )
    }
}
