import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach estimate is in its life cycle.
    enum OutreachEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A outreach estimate. Its code is unique within a tenant.
    final class OutreachEstimate {
        var code: String
        var name: String
        var segment: String
        var timezone: String
        var unit: String
        var amount: Double
        var status: OutreachEstimateStatus

        init(code: String, name: String, segment: String, timezone: String, unit: String, amount: Double, status: OutreachEstimateStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.timezone = timezone
            self.unit = unit
            self.amount = amount
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

        func canMoveTo(_ next: OutreachEstimateStatus) -> Bool {
            switch status {
            case .requested:
                return next == OutreachEstimateStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: OutreachEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("outreach estimate") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> OutreachEstimate {
            return OutreachEstimate(
                code: code,
                name: name,
                segment: segment,
                timezone: timezone,
                unit: unit,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a outreach estimate in status requested.
    static func newOutreachEstimate(_ code: String, name: String) -> OutreachEstimate {
        return OutreachEstimate(
            code: code,
            name: name,
            segment: "",
            timezone: "",
            unit: "",
            amount: 0.0,
            status: OutreachEstimateStatus.requested
        )
    }
}
