import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a capped charge group is in its life cycle.
    enum CappedChargeGroupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One capped charge group, with what the planners need to act on it.
    final class CappedChargeGroup {
        var code: String
        var label: String
        var timezone: String
        var ward: String
        var title: String
        var ownerID: String
        var startsAt: Int
        var status: CappedChargeGroupStatus

        init(code: String, label: String, timezone: String, ward: String, title: String, ownerID: String, startsAt: Int, status: CappedChargeGroupStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.ward = ward
            self.title = title
            self.ownerID = ownerID
            self.startsAt = startsAt
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

        func canMoveTo(_ next: CappedChargeGroupStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == CappedChargeGroupStatus.rejected || next == CappedChargeGroupStatus.withdrawn
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

        func moveTo(_ next: CappedChargeGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped charge group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("capped charge group") \(code)"
        }

        func measuredValue() -> Double {
            return Double(startsAt)
        }

        func copyValue() -> CappedChargeGroup {
            return CappedChargeGroup(
                code: code,
                label: label,
                timezone: timezone,
                ward: ward,
                title: title,
                ownerID: ownerID,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a capped charge group in status proposed.
    static func newCappedChargeGroup(_ code: String, label: String) -> CappedChargeGroup {
        return CappedChargeGroup(
            code: code,
            label: label,
            timezone: "",
            ward: "",
            title: "",
            ownerID: "",
            startsAt: 0,
            status: CappedChargeGroupStatus.proposed
        )
    }
}
