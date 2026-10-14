import AcmePlatform
import Foundation

extension Imaging {
    /// Where a manual study notice is in its life cycle.
    enum ManualStudyNoticeStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One manual study notice, with what the planners need to act on it.
    final class ManualStudyNotice {
        var code: String
        var title: String
        var facility: String
        var budget: Double
        var allergy: String
        var ceiling: Double
        var contactEmail: String
        var currency: String
        var segment: String
        var channel: String
        var floorValue: Double
        var status: ManualStudyNoticeStatus

        init(code: String, title: String, facility: String, budget: Double, allergy: String, ceiling: Double, contactEmail: String, currency: String, segment: String, channel: String, floorValue: Double, status: ManualStudyNoticeStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.budget = budget
            self.allergy = allergy
            self.ceiling = ceiling
            self.contactEmail = contactEmail
            self.currency = currency
            self.segment = segment
            self.channel = channel
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualStudyNoticeStatus) -> Bool {
            switch status {
            case .requested:
                return next == ManualStudyNoticeStatus.granted
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ManualStudyNoticeStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualStudyNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual study notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveLoad() -> Double {
            return (floorValue * budget * 100).rounded() / 100
        }

        func copyValue() -> ManualStudyNotice {
            return ManualStudyNotice(
                code: code,
                title: title,
                facility: facility,
                budget: budget,
                allergy: allergy,
                ceiling: ceiling,
                contactEmail: contactEmail,
                currency: currency,
                segment: segment,
                channel: channel,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a manual study notice in status requested.
    static func newManualStudyNotice(_ code: String, title: String) -> ManualStudyNotice {
        return ManualStudyNotice(
            code: code,
            title: title,
            facility: "",
            budget: 0.0,
            allergy: "",
            ceiling: 0.0,
            contactEmail: "",
            currency: "",
            segment: "",
            channel: "",
            floorValue: 0.0,
            status: ManualStudyNoticeStatus.requested
        )
    }
}
