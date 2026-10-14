import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a rolling denial audit is in its life cycle.
    enum RollingDenialAuditStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a rolling denial audit and its current status.
    final class RollingDenialAudit {
        var code: String
        var label: String
        var discount: Double
        var active: Bool
        var channel: String
        var currency: String
        var visitMinutes: Int
        var contactEmail: String
        var clinicianID: String
        var attributes: [String: String]
        var reviewer: String
        var status: RollingDenialAuditStatus

        init(code: String, label: String, discount: Double, active: Bool, channel: String, currency: String, visitMinutes: Int, contactEmail: String, clinicianID: String, attributes: [String: String], reviewer: String, status: RollingDenialAuditStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.active = active
            self.channel = channel
            self.currency = currency
            self.visitMinutes = visitMinutes
            self.contactEmail = contactEmail
            self.clinicianID = clinicianID
            self.attributes = attributes
            self.reviewer = reviewer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingDenialAuditStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == RollingDenialAuditStatus.withdrawn
            case .rejected:
                return next == RollingDenialAuditStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingDenialAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling denial audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
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

        func weightedValue() -> Double {
            return ((discount - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RollingDenialAudit {
            return RollingDenialAudit(
                code: code,
                label: label,
                discount: discount,
                active: active,
                channel: channel,
                currency: currency,
                visitMinutes: visitMinutes,
                contactEmail: contactEmail,
                clinicianID: clinicianID,
                attributes: attributes,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a rolling denial audit in status proposed.
    static func newRollingDenialAudit(_ code: String, label: String) -> RollingDenialAudit {
        return RollingDenialAudit(
            code: code,
            label: label,
            discount: 0.0,
            active: false,
            channel: "",
            currency: "",
            visitMinutes: 0,
            contactEmail: "",
            clinicianID: "",
            attributes: [:],
            reviewer: "",
            status: RollingDenialAuditStatus.proposed
        )
    }
}
