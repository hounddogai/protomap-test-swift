import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched outreach policy is in its life cycle.
    enum BatchedOutreachPolicyStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A batched outreach policy as the outreach team keeps it.
    final class BatchedOutreachPolicy {
        var code: String
        var name: String
        var visible: Bool
        var minimum: Double
        var pinned: Bool
        var budget: Double
        var windowDays: Int
        var createdAt: Int
        var diagnosisCode: String
        var status: BatchedOutreachPolicyStatus

        init(code: String, name: String, visible: Bool, minimum: Double, pinned: Bool, budget: Double, windowDays: Int, createdAt: Int, diagnosisCode: String, status: BatchedOutreachPolicyStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.minimum = minimum
            self.pinned = pinned
            self.budget = budget
            self.windowDays = windowDays
            self.createdAt = createdAt
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: BatchedOutreachPolicyStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == BatchedOutreachPolicyStatus.reopened
            case .reopened:
                return next == BatchedOutreachPolicyStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedOutreachPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched outreach policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedTotal() -> Double {
            return ((minimum + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedOutreachPolicy {
            return BatchedOutreachPolicy(
                code: code,
                name: name,
                visible: visible,
                minimum: minimum,
                pinned: pinned,
                budget: budget,
                windowDays: windowDays,
                createdAt: createdAt,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched outreach policy in status open.
    static func newBatchedOutreachPolicy(_ code: String, name: String) -> BatchedOutreachPolicy {
        return BatchedOutreachPolicy(
            code: code,
            name: name,
            visible: false,
            minimum: 0.0,
            pinned: false,
            budget: 0.0,
            windowDays: 0,
            createdAt: 0,
            diagnosisCode: "",
            status: BatchedOutreachPolicyStatus.`open`
        )
    }
}
