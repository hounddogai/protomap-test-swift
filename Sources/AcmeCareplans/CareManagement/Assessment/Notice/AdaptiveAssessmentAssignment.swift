import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive assessment assignment is in its life cycle.
    enum AdaptiveAssessmentAssignmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One adaptive assessment assignment, with what the planners need to act on it.
    final class AdaptiveAssessmentAssignment {
        var code: String
        var title: String
        var payer: String
        var timezone: String
        var source: String
        var quantity: Int
        var status: AdaptiveAssessmentAssignmentStatus

        init(code: String, title: String, payer: String, timezone: String, source: String, quantity: Int, status: AdaptiveAssessmentAssignmentStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.timezone = timezone
            self.source = source
            self.quantity = quantity
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

        func canMoveTo(_ next: AdaptiveAssessmentAssignmentStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: AdaptiveAssessmentAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive assessment assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> AdaptiveAssessmentAssignment {
            return AdaptiveAssessmentAssignment(
                code: code,
                title: title,
                payer: payer,
                timezone: timezone,
                source: source,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a adaptive assessment assignment in status idle.
    static func newAdaptiveAssessmentAssignment(_ code: String, title: String) -> AdaptiveAssessmentAssignment {
        return AdaptiveAssessmentAssignment(
            code: code,
            title: title,
            payer: "",
            timezone: "",
            source: "",
            quantity: 0,
            status: AdaptiveAssessmentAssignmentStatus.idle
        )
    }
}
