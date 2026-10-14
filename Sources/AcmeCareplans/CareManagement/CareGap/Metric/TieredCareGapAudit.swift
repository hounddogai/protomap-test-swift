import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered care gap audit is in its life cycle.
    enum TieredCareGapAuditStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A tiered care gap audit as the care gap team keeps it.
    final class TieredCareGapAudit {
        var code: String
        var title: String
        var attributes: [String: String]
        var checksum: String
        var allergy: String
        var durationMinutes: Int
        var status: TieredCareGapAuditStatus

        init(code: String, title: String, attributes: [String: String], checksum: String, allergy: String, durationMinutes: Int, status: TieredCareGapAuditStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.checksum = checksum
            self.allergy = allergy
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: TieredCareGapAuditStatus) -> Bool {
            switch status {
            case .requested:
                return next == TieredCareGapAuditStatus.revoked || next == TieredCareGapAuditStatus.expired
            case .granted:
                return next == TieredCareGapAuditStatus.revoked
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

        func moveTo(_ next: TieredCareGapAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered care gap audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("tiered care gap audit") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return Double(durationMinutes)
        }

        func copyValue() -> TieredCareGapAudit {
            return TieredCareGapAudit(
                code: code,
                title: title,
                attributes: attributes,
                checksum: checksum,
                allergy: allergy,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered care gap audit in status requested.
    static func newTieredCareGapAudit(_ code: String, title: String) -> TieredCareGapAudit {
        return TieredCareGapAudit(
            code: code,
            title: title,
            attributes: [:],
            checksum: "",
            allergy: "",
            durationMinutes: 0,
            status: TieredCareGapAuditStatus.requested
        )
    }
}
