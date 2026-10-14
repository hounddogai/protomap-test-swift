import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer metric is in its life cycle.
    enum TransferMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A transfer metric as the transfer team keeps it.
    final class TransferMetric {
        var code: String
        var name: String
        var locale: String
        var amount: Double
        var acuity: Int
        var ownerID: String
        var contactEmail: String
        var timezone: String
        var limit: Int
        var createdAt: Int
        var status: TransferMetricStatus

        init(code: String, name: String, locale: String, amount: Double, acuity: Int, ownerID: String, contactEmail: String, timezone: String, limit: Int, createdAt: Int, status: TransferMetricStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.amount = amount
            self.acuity = acuity
            self.ownerID = ownerID
            self.contactEmail = contactEmail
            self.timezone = timezone
            self.limit = limit
            self.createdAt = createdAt
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

        func canMoveTo(_ next: TransferMetricStatus) -> Bool {
            switch status {
            case .requested:
                return next == TransferMetricStatus.revoked
            case .granted:
                return next == TransferMetricStatus.revoked
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

        func moveTo(_ next: TransferMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedTotal() -> Double {
            return ((amount - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> TransferMetric {
            return TransferMetric(
                code: code,
                name: name,
                locale: locale,
                amount: amount,
                acuity: acuity,
                ownerID: ownerID,
                contactEmail: contactEmail,
                timezone: timezone,
                limit: limit,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a transfer metric in status requested.
    static func newTransferMetric(_ code: String, name: String) -> TransferMetric {
        return TransferMetric(
            code: code,
            name: name,
            locale: "",
            amount: 0.0,
            acuity: 0,
            ownerID: "",
            contactEmail: "",
            timezone: "",
            limit: 0,
            createdAt: 0,
            status: TransferMetricStatus.requested
        )
    }
}
