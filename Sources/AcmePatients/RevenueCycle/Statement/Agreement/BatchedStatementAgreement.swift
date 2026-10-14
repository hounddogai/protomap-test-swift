import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched statement agreement is in its life cycle.
    enum BatchedStatementAgreementStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A batched statement agreement. Its code is unique within a tenant.
    final class BatchedStatementAgreement {
        var code: String
        var name: String
        var category: String
        var margin: Double
        var budget: Double
        var contactEmail: String
        var copay: Double
        var ratio: Double
        var status: BatchedStatementAgreementStatus

        init(code: String, name: String, category: String, margin: Double, budget: Double, contactEmail: String, copay: Double, ratio: Double, status: BatchedStatementAgreementStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.margin = margin
            self.budget = budget
            self.contactEmail = contactEmail
            self.copay = copay
            self.ratio = ratio
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

        func canMoveTo(_ next: BatchedStatementAgreementStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == BatchedStatementAgreementStatus.failed
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

        func moveTo(_ next: BatchedStatementAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched statement agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netTotal() -> Double {
            return ((margin + budget) * 100).rounded() / 100
        }

        func copyValue() -> BatchedStatementAgreement {
            return BatchedStatementAgreement(
                code: code,
                name: name,
                category: category,
                margin: margin,
                budget: budget,
                contactEmail: contactEmail,
                copay: copay,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a batched statement agreement in status new.
    static func newBatchedStatementAgreement(_ code: String, name: String) -> BatchedStatementAgreement {
        return BatchedStatementAgreement(
            code: code,
            name: name,
            category: "",
            margin: 0.0,
            budget: 0.0,
            contactEmail: "",
            copay: 0.0,
            ratio: 0.0,
            status: BatchedStatementAgreementStatus.new
        )
    }
}
