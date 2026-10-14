import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol adjustment is in its life cycle.
    enum CareProtocolAdjustmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One care protocol adjustment, with what the planners need to act on it.
    final class CareProtocolAdjustment {
        var code: String
        var name: String
        var budget: Double
        var copay: Double
        var ceiling: Double
        var status: CareProtocolAdjustmentStatus

        init(code: String, name: String, budget: Double, copay: Double, ceiling: Double, status: CareProtocolAdjustmentStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.copay = copay
            self.ceiling = ceiling
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

        func canMoveTo(_ next: CareProtocolAdjustmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: CareProtocolAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveTotal() -> Double {
            return (ceiling * budget * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolAdjustment {
            return CareProtocolAdjustment(
                code: code,
                name: name,
                budget: budget,
                copay: copay,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care protocol adjustment in status requested.
    static func newCareProtocolAdjustment(_ code: String, name: String) -> CareProtocolAdjustment {
        return CareProtocolAdjustment(
            code: code,
            name: name,
            budget: 0.0,
            copay: 0.0,
            ceiling: 0.0,
            status: CareProtocolAdjustmentStatus.requested
        )
    }
}
