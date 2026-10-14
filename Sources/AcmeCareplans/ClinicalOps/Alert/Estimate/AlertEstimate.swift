import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert estimate is in its life cycle.
    enum AlertEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A alert estimate. Its code is unique within a tenant.
    final class AlertEstimate {
        var code: String
        var label: String
        var procedureCode: String
        var budget: Double
        var createdAt: Int
        var status: AlertEstimateStatus

        init(code: String, label: String, procedureCode: String, budget: Double, createdAt: Int, status: AlertEstimateStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.budget = budget
            self.createdAt = createdAt
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

        func canMoveTo(_ next: AlertEstimateStatus) -> Bool {
            switch status {
            case .requested:
                return next == AlertEstimateStatus.granted || next == AlertEstimateStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == AlertEstimateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netTotal() -> Double {
            return ((Double(createdAt) - budget) * 100).rounded() / 100
        }

        func copyValue() -> AlertEstimate {
            return AlertEstimate(
                code: code,
                label: label,
                procedureCode: procedureCode,
                budget: budget,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a alert estimate in status requested.
    static func newAlertEstimate(_ code: String, label: String) -> AlertEstimate {
        return AlertEstimate(
            code: code,
            label: label,
            procedureCode: "",
            budget: 0.0,
            createdAt: 0,
            status: AlertEstimateStatus.requested
        )
    }
}
