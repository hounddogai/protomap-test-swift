import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff request is in its life cycle.
    enum HandoffRequestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A handoff request as the handoff team keeps it.
    final class HandoffRequest {
        var code: String
        var name: String
        var archived: Bool
        var updatedAt: Int
        var acuity: Int
        var budget: Double
        var status: HandoffRequestStatus

        init(code: String, name: String, archived: Bool, updatedAt: Int, acuity: Int, budget: Double, status: HandoffRequestStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.updatedAt = updatedAt
            self.acuity = acuity
            self.budget = budget
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

        func canMoveTo(_ next: HandoffRequestStatus) -> Bool {
            switch status {
            case .idle:
                return next == HandoffRequestStatus.warming
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == HandoffRequestStatus.draining
            case .draining:
                return next == HandoffRequestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: HandoffRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedLoad() -> Double {
            return ((Double(acuity) - budget) * 100).rounded() / 100
        }

        func copyValue() -> HandoffRequest {
            return HandoffRequest(
                code: code,
                name: name,
                archived: archived,
                updatedAt: updatedAt,
                acuity: acuity,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a handoff request in status idle.
    static func newHandoffRequest(_ code: String, name: String) -> HandoffRequest {
        return HandoffRequest(
            code: code,
            name: name,
            archived: false,
            updatedAt: 0,
            acuity: 0,
            budget: 0.0,
            status: HandoffRequestStatus.idle
        )
    }
}
