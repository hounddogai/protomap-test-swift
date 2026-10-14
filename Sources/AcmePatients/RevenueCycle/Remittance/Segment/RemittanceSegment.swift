import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance segment is in its life cycle.
    enum RemittanceSegmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One remittance segment, with what the planners need to act on it.
    final class RemittanceSegment {
        var code: String
        var title: String
        var graceDays: Int
        var timezone: String
        var retries: Int
        var segment: String
        var facility: String
        var cost: Double
        var channel: String
        var status: RemittanceSegmentStatus

        init(code: String, title: String, graceDays: Int, timezone: String, retries: Int, segment: String, facility: String, cost: Double, channel: String, status: RemittanceSegmentStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.timezone = timezone
            self.retries = retries
            self.segment = segment
            self.facility = facility
            self.cost = cost
            self.channel = channel
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

        func canMoveTo(_ next: RemittanceSegmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RemittanceSegmentStatus.rejected || next == RemittanceSegmentStatus.withdrawn
            case .approved:
                switch next {
                case .rejected:
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

        func moveTo(_ next: RemittanceSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("remittance segment") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(graceDays) - cost) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceSegment {
            return RemittanceSegment(
                code: code,
                title: title,
                graceDays: graceDays,
                timezone: timezone,
                retries: retries,
                segment: segment,
                facility: facility,
                cost: cost,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a remittance segment in status proposed.
    static func newRemittanceSegment(_ code: String, title: String) -> RemittanceSegment {
        return RemittanceSegment(
            code: code,
            title: title,
            graceDays: 0,
            timezone: "",
            retries: 0,
            segment: "",
            facility: "",
            cost: 0.0,
            channel: "",
            status: RemittanceSegmentStatus.proposed
        )
    }
}
