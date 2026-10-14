import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy tier is in its life cycle.
    enum ProxyTierStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A proxy tier. Its code is unique within a tenant.
    final class ProxyTier {
        var code: String
        var name: String
        var timezone: String
        var approved: Bool
        var label: String
        var amount: Double
        var phone: String
        var bed: String
        var createdAt: Int
        var status: ProxyTierStatus

        init(code: String, name: String, timezone: String, approved: Bool, label: String, amount: Double, phone: String, bed: String, createdAt: Int, status: ProxyTierStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.approved = approved
            self.label = label
            self.amount = amount
            self.phone = phone
            self.bed = bed
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProxyTierStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ProxyTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedExposure() -> Double {
            return ((Double(createdAt) - amount) * 100).rounded() / 100
        }

        func copyValue() -> ProxyTier {
            return ProxyTier(
                code: code,
                name: name,
                timezone: timezone,
                approved: approved,
                label: label,
                amount: amount,
                phone: phone,
                bed: bed,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a proxy tier in status created.
    static func newProxyTier(_ code: String, name: String) -> ProxyTier {
        return ProxyTier(
            code: code,
            name: name,
            timezone: "",
            approved: false,
            label: "",
            amount: 0.0,
            phone: "",
            bed: "",
            createdAt: 0,
            status: ProxyTierStatus.created
        )
    }
}
