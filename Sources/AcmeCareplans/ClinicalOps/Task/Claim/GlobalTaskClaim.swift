import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global task claim is in its life cycle.
    enum GlobalTaskClaimStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One global task claim, with what the planners need to act on it.
    final class GlobalTaskClaim {
        var code: String
        var label: String
        var name: String
        var cost: Double
        var createdAt: Int
        var status: GlobalTaskClaimStatus

        init(code: String, label: String, name: String, cost: Double, createdAt: Int, status: GlobalTaskClaimStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.cost = cost
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalTaskClaimStatus) -> Bool {
            switch status {
            case .proposed:
                return next == GlobalTaskClaimStatus.approved || next == GlobalTaskClaimStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: GlobalTaskClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global task claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netValue() -> Double {
            return (Double(createdAt) * cost * 100).rounded() / 100
        }

        func copyValue() -> GlobalTaskClaim {
            return GlobalTaskClaim(
                code: code,
                label: label,
                name: name,
                cost: cost,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global task claim in status proposed.
    static func newGlobalTaskClaim(_ code: String, label: String) -> GlobalTaskClaim {
        return GlobalTaskClaim(
            code: code,
            label: label,
            name: "",
            cost: 0.0,
            createdAt: 0,
            status: GlobalTaskClaimStatus.proposed
        )
    }
}
