import AcmePlatform
import Foundation

extension Consent {
    /// Where a pending consent form allocation is in its life cycle.
    enum PendingConsentFormAllocationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a pending consent form allocation and its current status.
    final class PendingConsentFormAllocation {
        var code: String
        var name: String
        var visible: Bool
        var margin: Double
        var reviewer: String
        var status: PendingConsentFormAllocationStatus

        init(code: String, name: String, visible: Bool, margin: Double, reviewer: String, status: PendingConsentFormAllocationStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.margin = margin
            self.reviewer = reviewer
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

        func canMoveTo(_ next: PendingConsentFormAllocationStatus) -> Bool {
            switch status {
            case .requested:
                return next == PendingConsentFormAllocationStatus.granted
            case .granted:
                return next == PendingConsentFormAllocationStatus.revoked || next == PendingConsentFormAllocationStatus.expired
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

        func moveTo(_ next: PendingConsentFormAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending consent form allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> PendingConsentFormAllocation {
            return PendingConsentFormAllocation(
                code: code,
                name: name,
                visible: visible,
                margin: margin,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending consent form allocation in status requested.
    static func newPendingConsentFormAllocation(_ code: String, name: String) -> PendingConsentFormAllocation {
        return PendingConsentFormAllocation(
            code: code,
            name: name,
            visible: false,
            margin: 0.0,
            reviewer: "",
            status: PendingConsentFormAllocationStatus.requested
        )
    }
}
