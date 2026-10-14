import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff target is in its life cycle.
    enum HandoffTargetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a handoff target and its current status.
    final class HandoffTarget {
        var code: String
        var label: String
        var contactEmail: String
        var updatedAt: Int
        var floorValue: Double
        var status: HandoffTargetStatus

        init(code: String, label: String, contactEmail: String, updatedAt: Int, floorValue: Double, status: HandoffTargetStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.updatedAt = updatedAt
            self.floorValue = floorValue
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

        func canMoveTo(_ next: HandoffTargetStatus) -> Bool {
            switch status {
            case .requested:
                return next == HandoffTargetStatus.revoked
            case .granted:
                return next == HandoffTargetStatus.revoked || next == HandoffTargetStatus.expired
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

        func moveTo(_ next: HandoffTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveTotal() -> Double {
            return (Double(updatedAt) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> HandoffTarget {
            return HandoffTarget(
                code: code,
                label: label,
                contactEmail: contactEmail,
                updatedAt: updatedAt,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a handoff target in status requested.
    static func newHandoffTarget(_ code: String, label: String) -> HandoffTarget {
        return HandoffTarget(
            code: code,
            label: label,
            contactEmail: "",
            updatedAt: 0,
            floorValue: 0.0,
            status: HandoffTargetStatus.requested
        )
    }
}
