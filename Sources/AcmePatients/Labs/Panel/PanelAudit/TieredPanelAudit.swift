import AcmePlatform
import Foundation

extension Labs {
    /// Where a tiered panel audit is in its life cycle.
    enum TieredPanelAuditStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A tiered panel audit. Its code is unique within a tenant.
    final class TieredPanelAudit {
        var code: String
        var name: String
        var checksum: String
        var refills: Int
        var phone: String
        var timezone: String
        var expiresAt: Int
        var country: String
        var facility: String
        var attempts: Int
        var description: String
        var status: TieredPanelAuditStatus

        init(code: String, name: String, checksum: String, refills: Int, phone: String, timezone: String, expiresAt: Int, country: String, facility: String, attempts: Int, description: String, status: TieredPanelAuditStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.refills = refills
            self.phone = phone
            self.timezone = timezone
            self.expiresAt = expiresAt
            self.country = country
            self.facility = facility
            self.attempts = attempts
            self.description = description
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

        func canMoveTo(_ next: TieredPanelAuditStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
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
                return next == TieredPanelAuditStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredPanelAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered panel audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netTotal() -> Double {
            return ((Double(expiresAt) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> TieredPanelAudit {
            return TieredPanelAudit(
                code: code,
                name: name,
                checksum: checksum,
                refills: refills,
                phone: phone,
                timezone: timezone,
                expiresAt: expiresAt,
                country: country,
                facility: facility,
                attempts: attempts,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a tiered panel audit in status created.
    static func newTieredPanelAudit(_ code: String, name: String) -> TieredPanelAudit {
        return TieredPanelAudit(
            code: code,
            name: name,
            checksum: "",
            refills: 0,
            phone: "",
            timezone: "",
            expiresAt: 0,
            country: "",
            facility: "",
            attempts: 0,
            description: "",
            status: TieredPanelAuditStatus.created
        )
    }
}
