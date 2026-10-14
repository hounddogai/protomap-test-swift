import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility audit is in its life cycle.
    enum EligibilityAuditStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A eligibility audit. Its code is unique within a tenant.
    final class EligibilityAudit {
        var code: String
        var title: String
        var amount: Double
        var batchSize: Int
        var attributes: [String: String]
        var archived: Bool
        var currency: String
        var reviewer: String
        var status: EligibilityAuditStatus

        init(code: String, title: String, amount: Double, batchSize: Int, attributes: [String: String], archived: Bool, currency: String, reviewer: String, status: EligibilityAuditStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.batchSize = batchSize
            self.attributes = attributes
            self.archived = archived
            self.currency = currency
            self.reviewer = reviewer
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

        func canMoveTo(_ next: EligibilityAuditStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == EligibilityAuditStatus.running
            case .running:
                return next == EligibilityAuditStatus.failed
            case .done:
                return next == EligibilityAuditStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
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

        func projectedValue() -> Double {
            return ((amount + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityAudit {
            return EligibilityAudit(
                code: code,
                title: title,
                amount: amount,
                batchSize: batchSize,
                attributes: attributes,
                archived: archived,
                currency: currency,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a eligibility audit in status new.
    static func newEligibilityAudit(_ code: String, title: String) -> EligibilityAudit {
        return EligibilityAudit(
            code: code,
            title: title,
            amount: 0.0,
            batchSize: 0,
            attributes: [:],
            archived: false,
            currency: "",
            reviewer: "",
            status: EligibilityAuditStatus.new
        )
    }
}
