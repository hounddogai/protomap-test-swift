import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime rule is in its life cycle.
    enum OvertimeRuleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a overtime rule and its current status.
    final class OvertimeRule {
        var code: String
        var label: String
        var threshold: Double
        var procedureCode: String
        var maximum: Double
        var createdAt: Int
        var tags: [String]
        var payer: String
        var attributes: [String: String]
        var status: OvertimeRuleStatus

        init(code: String, label: String, threshold: Double, procedureCode: String, maximum: Double, createdAt: Int, tags: [String], payer: String, attributes: [String: String], status: OvertimeRuleStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.procedureCode = procedureCode
            self.maximum = maximum
            self.createdAt = createdAt
            self.tags = tags
            self.payer = payer
            self.attributes = attributes
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

        func canMoveTo(_ next: OvertimeRuleStatus) -> Bool {
            switch status {
            case .requested:
                return next == OvertimeRuleStatus.granted || next == OvertimeRuleStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == OvertimeRuleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimeRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
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

        func adjustedExposure() -> Double {
            return ((threshold + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeRule {
            return OvertimeRule(
                code: code,
                label: label,
                threshold: threshold,
                procedureCode: procedureCode,
                maximum: maximum,
                createdAt: createdAt,
                tags: tags,
                payer: payer,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a overtime rule in status requested.
    static func newOvertimeRule(_ code: String, label: String) -> OvertimeRule {
        return OvertimeRule(
            code: code,
            label: label,
            threshold: 0.0,
            procedureCode: "",
            maximum: 0.0,
            createdAt: 0,
            tags: [],
            payer: "",
            attributes: [:],
            status: OvertimeRuleStatus.requested
        )
    }
}
