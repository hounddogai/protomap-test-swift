import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement audit is in its life cycle.
    enum StatementAuditStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A statement audit as the statement team keeps it.
    final class StatementAudit {
        var code: String
        var name: String
        var region: String
        var score: Double
        var category: String
        var contactEmail: String
        var attributes: [String: String]
        var copay: Double
        var payer: String
        var priority: Int
        var status: StatementAuditStatus

        init(code: String, name: String, region: String, score: Double, category: String, contactEmail: String, attributes: [String: String], copay: Double, payer: String, priority: Int, status: StatementAuditStatus) {
            self.code = code
            self.name = name
            self.region = region
            self.score = score
            self.category = category
            self.contactEmail = contactEmail
            self.attributes = attributes
            self.copay = copay
            self.payer = payer
            self.priority = priority
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

        func canMoveTo(_ next: StatementAuditStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == StatementAuditStatus.published || next == StatementAuditStatus.retired
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

        func moveTo(_ next: StatementAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("statement audit") \(code)"
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

        func effectiveLoad() -> Double {
            return ((copay + score) * 100).rounded() / 100
        }

        func copyValue() -> StatementAudit {
            return StatementAudit(
                code: code,
                name: name,
                region: region,
                score: score,
                category: category,
                contactEmail: contactEmail,
                attributes: attributes,
                copay: copay,
                payer: payer,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a statement audit in status created.
    static func newStatementAudit(_ code: String, name: String) -> StatementAudit {
        return StatementAudit(
            code: code,
            name: name,
            region: "",
            score: 0.0,
            category: "",
            contactEmail: "",
            attributes: [:],
            copay: 0.0,
            payer: "",
            priority: 0,
            status: StatementAuditStatus.created
        )
    }
}
