import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction exception is in its life cycle.
    enum InteractionExceptionStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A interaction exception as the interaction team keeps it.
    final class InteractionException {
        var code: String
        var label: String
        var ownerID: String
        var createdAt: Int
        var title: String
        var budget: Double
        var approved: Bool
        var ceiling: Double
        var status: InteractionExceptionStatus

        init(code: String, label: String, ownerID: String, createdAt: Int, title: String, budget: Double, approved: Bool, ceiling: Double, status: InteractionExceptionStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.createdAt = createdAt
            self.title = title
            self.budget = budget
            self.approved = approved
            self.ceiling = ceiling
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

        func canMoveTo(_ next: InteractionExceptionStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: InteractionExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedValue() -> Double {
            return ((ceiling + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> InteractionException {
            return InteractionException(
                code: code,
                label: label,
                ownerID: ownerID,
                createdAt: createdAt,
                title: title,
                budget: budget,
                approved: approved,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a interaction exception in status proposed.
    static func newInteractionException(_ code: String, label: String) -> InteractionException {
        return InteractionException(
            code: code,
            label: label,
            ownerID: "",
            createdAt: 0,
            title: "",
            budget: 0.0,
            approved: false,
            ceiling: 0.0,
            status: InteractionExceptionStatus.proposed
        )
    }
}
