import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a primary goal proposal is in its life cycle.
    enum PrimaryGoalProposalStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One primary goal proposal, with what the planners need to act on it.
    final class PrimaryGoalProposal {
        var code: String
        var label: String
        var maximum: Double
        var createdAt: Int
        var quantity: Int
        var visitMinutes: Int
        var durationMinutes: Int
        var priority: Int
        var capacity: Int
        var ratio: Double
        var status: PrimaryGoalProposalStatus

        init(code: String, label: String, maximum: Double, createdAt: Int, quantity: Int, visitMinutes: Int, durationMinutes: Int, priority: Int, capacity: Int, ratio: Double, status: PrimaryGoalProposalStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.createdAt = createdAt
            self.quantity = quantity
            self.visitMinutes = visitMinutes
            self.durationMinutes = durationMinutes
            self.priority = priority
            self.capacity = capacity
            self.ratio = ratio
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

        func canMoveTo(_ next: PrimaryGoalProposalStatus) -> Bool {
            switch status {
            case .requested:
                return next == PrimaryGoalProposalStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == PrimaryGoalProposalStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryGoalProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary goal proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveExposure() -> Double {
            return ((maximum - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryGoalProposal {
            return PrimaryGoalProposal(
                code: code,
                label: label,
                maximum: maximum,
                createdAt: createdAt,
                quantity: quantity,
                visitMinutes: visitMinutes,
                durationMinutes: durationMinutes,
                priority: priority,
                capacity: capacity,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary goal proposal in status requested.
    static func newPrimaryGoalProposal(_ code: String, label: String) -> PrimaryGoalProposal {
        return PrimaryGoalProposal(
            code: code,
            label: label,
            maximum: 0.0,
            createdAt: 0,
            quantity: 0,
            visitMinutes: 0,
            durationMinutes: 0,
            priority: 0,
            capacity: 0,
            ratio: 0.0,
            status: PrimaryGoalProposalStatus.requested
        )
    }
}
