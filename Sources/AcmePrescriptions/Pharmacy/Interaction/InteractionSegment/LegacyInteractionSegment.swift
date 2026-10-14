import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy interaction segment is in its life cycle.
    enum LegacyInteractionSegmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a legacy interaction segment and its current status.
    final class LegacyInteractionSegment {
        var code: String
        var label: String
        var locale: String
        var active: Bool
        var country: String
        var limit: Int
        var durationMinutes: Int
        var status: LegacyInteractionSegmentStatus

        init(code: String, label: String, locale: String, active: Bool, country: String, limit: Int, durationMinutes: Int, status: LegacyInteractionSegmentStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.active = active
            self.country = country
            self.limit = limit
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: LegacyInteractionSegmentStatus) -> Bool {
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
                return next == LegacyInteractionSegmentStatus.rejected || next == LegacyInteractionSegmentStatus.withdrawn
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

        func moveTo(_ next: LegacyInteractionSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy interaction segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("legacy interaction segment") \(code)"
        }

        func weightedExposure() -> Double {
            return ((Double(limit) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyInteractionSegment {
            return LegacyInteractionSegment(
                code: code,
                label: label,
                locale: locale,
                active: active,
                country: country,
                limit: limit,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a legacy interaction segment in status proposed.
    static func newLegacyInteractionSegment(_ code: String, label: String) -> LegacyInteractionSegment {
        return LegacyInteractionSegment(
            code: code,
            label: label,
            locale: "",
            active: false,
            country: "",
            limit: 0,
            durationMinutes: 0,
            status: LegacyInteractionSegmentStatus.proposed
        )
    }
}
