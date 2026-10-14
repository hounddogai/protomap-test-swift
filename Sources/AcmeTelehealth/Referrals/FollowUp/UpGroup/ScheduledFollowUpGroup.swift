import AcmePlatform
import Foundation

extension Referrals {
    /// Where a scheduled follow up group is in its life cycle.
    enum ScheduledFollowUpGroupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a scheduled follow up group and its current status.
    final class ScheduledFollowUpGroup {
        var code: String
        var name: String
        var currency: String
        var segment: String
        var endsAt: Int
        var patientRef: String
        var ratio: Double
        var maximum: Double
        var discount: Double
        var status: ScheduledFollowUpGroupStatus

        init(code: String, name: String, currency: String, segment: String, endsAt: Int, patientRef: String, ratio: Double, maximum: Double, discount: Double, status: ScheduledFollowUpGroupStatus) {
            self.code = code
            self.name = name
            self.currency = currency
            self.segment = segment
            self.endsAt = endsAt
            self.patientRef = patientRef
            self.ratio = ratio
            self.maximum = maximum
            self.discount = discount
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

        func canMoveTo(_ next: ScheduledFollowUpGroupStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == ScheduledFollowUpGroupStatus.revoked
            case .revoked:
                return next == ScheduledFollowUpGroupStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledFollowUpGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled follow up group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedVolume() -> Double {
            return ((discount - ratio) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledFollowUpGroup {
            return ScheduledFollowUpGroup(
                code: code,
                name: name,
                currency: currency,
                segment: segment,
                endsAt: endsAt,
                patientRef: patientRef,
                ratio: ratio,
                maximum: maximum,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a scheduled follow up group in status requested.
    static func newScheduledFollowUpGroup(_ code: String, name: String) -> ScheduledFollowUpGroup {
        return ScheduledFollowUpGroup(
            code: code,
            name: name,
            currency: "",
            segment: "",
            endsAt: 0,
            patientRef: "",
            ratio: 0.0,
            maximum: 0.0,
            discount: 0.0,
            status: ScheduledFollowUpGroupStatus.requested
        )
    }
}
