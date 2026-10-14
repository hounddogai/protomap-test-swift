import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling care protocol audit is in its life cycle.
    enum RollingCareProtocolAuditStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A rolling care protocol audit as the care protocol team keeps it.
    final class RollingCareProtocolAudit {
        var code: String
        var label: String
        var endsAt: Int
        var copay: Double
        var minimum: Double
        var attributes: [String: String]
        var durationMinutes: Int
        var active: Bool
        var checksum: String
        var phone: String
        var externalRef: String
        var status: RollingCareProtocolAuditStatus

        init(code: String, label: String, endsAt: Int, copay: Double, minimum: Double, attributes: [String: String], durationMinutes: Int, active: Bool, checksum: String, phone: String, externalRef: String, status: RollingCareProtocolAuditStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.copay = copay
            self.minimum = minimum
            self.attributes = attributes
            self.durationMinutes = durationMinutes
            self.active = active
            self.checksum = checksum
            self.phone = phone
            self.externalRef = externalRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingCareProtocolAuditStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RollingCareProtocolAuditStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == RollingCareProtocolAuditStatus.reopened
            case .reopened:
                return next == RollingCareProtocolAuditStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingCareProtocolAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling care protocol audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
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

        func weightedExposure() -> Double {
            return ((copay + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> RollingCareProtocolAudit {
            return RollingCareProtocolAudit(
                code: code,
                label: label,
                endsAt: endsAt,
                copay: copay,
                minimum: minimum,
                attributes: attributes,
                durationMinutes: durationMinutes,
                active: active,
                checksum: checksum,
                phone: phone,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling care protocol audit in status open.
    static func newRollingCareProtocolAudit(_ code: String, label: String) -> RollingCareProtocolAudit {
        return RollingCareProtocolAudit(
            code: code,
            label: label,
            endsAt: 0,
            copay: 0.0,
            minimum: 0.0,
            attributes: [:],
            durationMinutes: 0,
            active: false,
            checksum: "",
            phone: "",
            externalRef: "",
            status: RollingCareProtocolAuditStatus.`open`
        )
    }
}
