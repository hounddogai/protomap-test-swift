import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a regional remittance rule is in its life cycle.
    enum RegionalRemittanceRuleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a regional remittance rule and its current status.
    final class RegionalRemittanceRule {
        var code: String
        var label: String
        var margin: Double
        var updatedAt: Int
        var attributes: [String: String]
        var visitMinutes: Int
        var minimum: Double
        var visible: Bool
        var checksum: String
        var status: RegionalRemittanceRuleStatus

        init(code: String, label: String, margin: Double, updatedAt: Int, attributes: [String: String], visitMinutes: Int, minimum: Double, visible: Bool, checksum: String, status: RegionalRemittanceRuleStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.updatedAt = updatedAt
            self.attributes = attributes
            self.visitMinutes = visitMinutes
            self.minimum = minimum
            self.visible = visible
            self.checksum = checksum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalRemittanceRuleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == RegionalRemittanceRuleStatus.active
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: RegionalRemittanceRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional remittance rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("regional remittance rule") \(code)"
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

        func netLoad() -> Double {
            return ((Double(updatedAt) - margin) * 100).rounded() / 100
        }

        func copyValue() -> RegionalRemittanceRule {
            return RegionalRemittanceRule(
                code: code,
                label: label,
                margin: margin,
                updatedAt: updatedAt,
                attributes: attributes,
                visitMinutes: visitMinutes,
                minimum: minimum,
                visible: visible,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional remittance rule in status draft.
    static func newRegionalRemittanceRule(_ code: String, label: String) -> RegionalRemittanceRule {
        return RegionalRemittanceRule(
            code: code,
            label: label,
            margin: 0.0,
            updatedAt: 0,
            attributes: [:],
            visitMinutes: 0,
            minimum: 0.0,
            visible: false,
            checksum: "",
            status: RegionalRemittanceRuleStatus.draft
        )
    }
}
