import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime quota is in its life cycle.
    enum OvertimeQuotaStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a overtime quota and its current status.
    final class OvertimeQuota {
        var code: String
        var label: String
        var category: String
        var maximum: Double
        var archived: Bool
        var cost: Double
        var phone: String
        var name: String
        var currency: String
        var version: Int
        var channel: String
        var status: OvertimeQuotaStatus

        init(code: String, label: String, category: String, maximum: Double, archived: Bool, cost: Double, phone: String, name: String, currency: String, version: Int, channel: String, status: OvertimeQuotaStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.maximum = maximum
            self.archived = archived
            self.cost = cost
            self.phone = phone
            self.name = name
            self.currency = currency
            self.version = version
            self.channel = channel
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

        func canMoveTo(_ next: OvertimeQuotaStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == OvertimeQuotaStatus.expired
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

        func moveTo(_ next: OvertimeQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("overtime quota") \(code)"
        }

        func weightedLoad() -> Double {
            return (cost * maximum * 100).rounded() / 100
        }

        func copyValue() -> OvertimeQuota {
            return OvertimeQuota(
                code: code,
                label: label,
                category: category,
                maximum: maximum,
                archived: archived,
                cost: cost,
                phone: phone,
                name: name,
                currency: currency,
                version: version,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a overtime quota in status requested.
    static func newOvertimeQuota(_ code: String, label: String) -> OvertimeQuota {
        return OvertimeQuota(
            code: code,
            label: label,
            category: "",
            maximum: 0.0,
            archived: false,
            cost: 0.0,
            phone: "",
            name: "",
            currency: "",
            version: 0,
            channel: "",
            status: OvertimeQuotaStatus.requested
        )
    }
}
