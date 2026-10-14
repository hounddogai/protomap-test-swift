import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction allocation is in its life cycle.
    enum InteractionAllocationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A interaction allocation as the interaction team keeps it.
    final class InteractionAllocation {
        var code: String
        var name: String
        var sequence: Int
        var cost: Double
        var approved: Bool
        var reviewer: String
        var attributes: [String: String]
        var status: InteractionAllocationStatus

        init(code: String, name: String, sequence: Int, cost: Double, approved: Bool, reviewer: String, attributes: [String: String], status: InteractionAllocationStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.cost = cost
            self.approved = approved
            self.reviewer = reviewer
            self.attributes = attributes
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

        func canMoveTo(_ next: InteractionAllocationStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == InteractionAllocationStatus.suspended
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

        func moveTo(_ next: InteractionAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedTotal() -> Double {
            return ((cost - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> InteractionAllocation {
            return InteractionAllocation(
                code: code,
                name: name,
                sequence: sequence,
                cost: cost,
                approved: approved,
                reviewer: reviewer,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a interaction allocation in status draft.
    static func newInteractionAllocation(_ code: String, name: String) -> InteractionAllocation {
        return InteractionAllocation(
            code: code,
            name: name,
            sequence: 0,
            cost: 0.0,
            approved: false,
            reviewer: "",
            attributes: [:],
            status: InteractionAllocationStatus.draft
        )
    }
}
