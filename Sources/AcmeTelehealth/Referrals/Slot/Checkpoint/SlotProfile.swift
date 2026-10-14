import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot profile is in its life cycle.
    enum SlotProfileStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One slot profile, with what the planners need to act on it.
    final class SlotProfile {
        var code: String
        var title: String
        var country: String
        var unit: String
        var reviewer: String
        var bed: String
        var pinned: Bool
        var timezone: String
        var minimum: Double
        var locale: String
        var visible: Bool
        var status: SlotProfileStatus

        init(code: String, title: String, country: String, unit: String, reviewer: String, bed: String, pinned: Bool, timezone: String, minimum: Double, locale: String, visible: Bool, status: SlotProfileStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.unit = unit
            self.reviewer = reviewer
            self.bed = bed
            self.pinned = pinned
            self.timezone = timezone
            self.minimum = minimum
            self.locale = locale
            self.visible = visible
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

        func canMoveTo(_ next: SlotProfileStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == SlotProfileStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> SlotProfile {
            return SlotProfile(
                code: code,
                title: title,
                country: country,
                unit: unit,
                reviewer: reviewer,
                bed: bed,
                pinned: pinned,
                timezone: timezone,
                minimum: minimum,
                locale: locale,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a slot profile in status proposed.
    static func newSlotProfile(_ code: String, title: String) -> SlotProfile {
        return SlotProfile(
            code: code,
            title: title,
            country: "",
            unit: "",
            reviewer: "",
            bed: "",
            pinned: false,
            timezone: "",
            minimum: 0.0,
            locale: "",
            visible: false,
            status: SlotProfileStatus.proposed
        )
    }
}
