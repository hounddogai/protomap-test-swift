import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement rule is in its life cycle.
    enum StatementRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A statement rule. Its code is unique within a tenant.
    final class StatementRule {
        var code: String
        var label: String
        var pinned: Bool
        var score: Double
        var externalRef: String
        var region: String
        var createdAt: Int
        var visitMinutes: Int
        var currency: String
        var approved: Bool
        var status: StatementRuleStatus

        init(code: String, label: String, pinned: Bool, score: Double, externalRef: String, region: String, createdAt: Int, visitMinutes: Int, currency: String, approved: Bool, status: StatementRuleStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.score = score
            self.externalRef = externalRef
            self.region = region
            self.createdAt = createdAt
            self.visitMinutes = visitMinutes
            self.currency = currency
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StatementRuleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == StatementRuleStatus.done
            case .running:
                return next == StatementRuleStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: StatementRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("statement rule") \(code)"
        }

        func adjustedValue() -> Double {
            return (Double(visitMinutes) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> StatementRule {
            return StatementRule(
                code: code,
                label: label,
                pinned: pinned,
                score: score,
                externalRef: externalRef,
                region: region,
                createdAt: createdAt,
                visitMinutes: visitMinutes,
                currency: currency,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a statement rule in status new.
    static func newStatementRule(_ code: String, label: String) -> StatementRule {
        return StatementRule(
            code: code,
            label: label,
            pinned: false,
            score: 0.0,
            externalRef: "",
            region: "",
            createdAt: 0,
            visitMinutes: 0,
            currency: "",
            approved: false,
            status: StatementRuleStatus.new
        )
    }
}
