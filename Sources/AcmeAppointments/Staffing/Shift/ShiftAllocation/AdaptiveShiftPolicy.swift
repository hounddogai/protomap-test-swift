import AcmePlatform
import Foundation

extension Staffing {
    /// Where a adaptive shift policy is in its life cycle.
    enum AdaptiveShiftPolicyStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a adaptive shift policy and its current status.
    final class AdaptiveShiftPolicy {
        var code: String
        var name: String
        var archived: Bool
        var payer: String
        var expiresAt: Int
        var minimum: Double
        var status: AdaptiveShiftPolicyStatus

        init(code: String, name: String, archived: Bool, payer: String, expiresAt: Int, minimum: Double, status: AdaptiveShiftPolicyStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.payer = payer
            self.expiresAt = expiresAt
            self.minimum = minimum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveShiftPolicyStatus) -> Bool {
            switch status {
            case .draft:
                return next == AdaptiveShiftPolicyStatus.active
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == AdaptiveShiftPolicyStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: AdaptiveShiftPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive shift policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedExposure() -> Double {
            return (minimum * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveShiftPolicy {
            return AdaptiveShiftPolicy(
                code: code,
                name: name,
                archived: archived,
                payer: payer,
                expiresAt: expiresAt,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive shift policy in status draft.
    static func newAdaptiveShiftPolicy(_ code: String, name: String) -> AdaptiveShiftPolicy {
        return AdaptiveShiftPolicy(
            code: code,
            name: name,
            archived: false,
            payer: "",
            expiresAt: 0,
            minimum: 0.0,
            status: AdaptiveShiftPolicyStatus.draft
        )
    }
}
