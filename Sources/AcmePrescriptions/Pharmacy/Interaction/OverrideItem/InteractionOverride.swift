import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction override is in its life cycle.
    enum InteractionOverrideStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a interaction override and its current status.
    final class InteractionOverride {
        var code: String
        var title: String
        var active: Bool
        var specialty: String
        var sequence: Int
        var status: InteractionOverrideStatus

        init(code: String, title: String, active: Bool, specialty: String, sequence: Int, status: InteractionOverrideStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.specialty = specialty
            self.sequence = sequence
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InteractionOverrideStatus) -> Bool {
            switch status {
            case .`open`:
                return next == InteractionOverrideStatus.reopened
            case .inReview:
                return next == InteractionOverrideStatus.archived
            case .resolved:
                return next == InteractionOverrideStatus.reopened
            case .reopened:
                return next == InteractionOverrideStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InteractionOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(sequence)
        }

        func copyValue() -> InteractionOverride {
            return InteractionOverride(
                code: code,
                title: title,
                active: active,
                specialty: specialty,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a interaction override in status open.
    static func newInteractionOverride(_ code: String, title: String) -> InteractionOverride {
        return InteractionOverride(
            code: code,
            title: title,
            active: false,
            specialty: "",
            sequence: 0,
            status: InteractionOverrideStatus.`open`
        )
    }
}
