import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global handoff request is in its life cycle.
    enum GlobalHandoffRequestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One global handoff request, with what the planners need to act on it.
    final class GlobalHandoffRequest {
        var code: String
        var label: String
        var ratio: Double
        var category: String
        var expiresAt: Int
        var budget: Double
        var status: GlobalHandoffRequestStatus

        init(code: String, label: String, ratio: Double, category: String, expiresAt: Int, budget: Double, status: GlobalHandoffRequestStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.category = category
            self.expiresAt = expiresAt
            self.budget = budget
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

        func canMoveTo(_ next: GlobalHandoffRequestStatus) -> Bool {
            switch status {
            case .created:
                return next == GlobalHandoffRequestStatus.validated
            case .validated:
                return next == GlobalHandoffRequestStatus.published || next == GlobalHandoffRequestStatus.retired
            case .published:
                return next == GlobalHandoffRequestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalHandoffRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global handoff request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveLoad() -> Double {
            return (Double(expiresAt) * ratio * 100).rounded() / 100
        }

        func copyValue() -> GlobalHandoffRequest {
            return GlobalHandoffRequest(
                code: code,
                label: label,
                ratio: ratio,
                category: category,
                expiresAt: expiresAt,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a global handoff request in status created.
    static func newGlobalHandoffRequest(_ code: String, label: String) -> GlobalHandoffRequest {
        return GlobalHandoffRequest(
            code: code,
            label: label,
            ratio: 0.0,
            category: "",
            expiresAt: 0,
            budget: 0.0,
            status: GlobalHandoffRequestStatus.created
        )
    }
}
