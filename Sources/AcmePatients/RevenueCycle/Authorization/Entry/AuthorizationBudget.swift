import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization budget is in its life cycle.
    enum AuthorizationBudgetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A authorization budget as the authorization team keeps it.
    final class AuthorizationBudget {
        var code: String
        var label: String
        var diagnosisCode: String
        var summary: String
        var procedureCode: String
        var ceiling: Double
        var bed: String
        var pinned: Bool
        var margin: Double
        var ward: String
        var status: AuthorizationBudgetStatus

        init(code: String, label: String, diagnosisCode: String, summary: String, procedureCode: String, ceiling: Double, bed: String, pinned: Bool, margin: Double, ward: String, status: AuthorizationBudgetStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.summary = summary
            self.procedureCode = procedureCode
            self.ceiling = ceiling
            self.bed = bed
            self.pinned = pinned
            self.margin = margin
            self.ward = ward
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AuthorizationBudgetStatus) -> Bool {
            switch status {
            case .idle:
                return next == AuthorizationBudgetStatus.warming || next == AuthorizationBudgetStatus.ready
            case .warming:
                return next == AuthorizationBudgetStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: AuthorizationBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedValue() -> Double {
            return (margin * ceiling * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationBudget {
            return AuthorizationBudget(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                summary: summary,
                procedureCode: procedureCode,
                ceiling: ceiling,
                bed: bed,
                pinned: pinned,
                margin: margin,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a authorization budget in status idle.
    static func newAuthorizationBudget(_ code: String, label: String) -> AuthorizationBudget {
        return AuthorizationBudget(
            code: code,
            label: label,
            diagnosisCode: "",
            summary: "",
            procedureCode: "",
            ceiling: 0.0,
            bed: "",
            pinned: false,
            margin: 0.0,
            ward: "",
            status: AuthorizationBudgetStatus.idle
        )
    }
}
