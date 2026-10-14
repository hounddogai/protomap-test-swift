import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol estimate is in its life cycle.
    enum CareProtocolEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A care protocol estimate as the care protocol team keeps it.
    final class CareProtocolEstimate {
        var code: String
        var label: String
        var channel: String
        var contactEmail: String
        var cost: Double
        var procedureCode: String
        var timezone: String
        var ceiling: Double
        var endsAt: Int
        var status: CareProtocolEstimateStatus

        init(code: String, label: String, channel: String, contactEmail: String, cost: Double, procedureCode: String, timezone: String, ceiling: Double, endsAt: Int, status: CareProtocolEstimateStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.contactEmail = contactEmail
            self.cost = cost
            self.procedureCode = procedureCode
            self.timezone = timezone
            self.ceiling = ceiling
            self.endsAt = endsAt
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

        func canMoveTo(_ next: CareProtocolEstimateStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == CareProtocolEstimateStatus.expired
            case .revoked:
                return next == CareProtocolEstimateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedExposure() -> Double {
            return ((cost + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolEstimate {
            return CareProtocolEstimate(
                code: code,
                label: label,
                channel: channel,
                contactEmail: contactEmail,
                cost: cost,
                procedureCode: procedureCode,
                timezone: timezone,
                ceiling: ceiling,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a care protocol estimate in status requested.
    static func newCareProtocolEstimate(_ code: String, label: String) -> CareProtocolEstimate {
        return CareProtocolEstimate(
            code: code,
            label: label,
            channel: "",
            contactEmail: "",
            cost: 0.0,
            procedureCode: "",
            timezone: "",
            ceiling: 0.0,
            endsAt: 0,
            status: CareProtocolEstimateStatus.requested
        )
    }
}
