import AcmePlatform
import Foundation

extension Imaging {
    /// Where a global priority agreement is in its life cycle.
    enum GlobalPriorityAgreementStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One global priority agreement, with what the planners need to act on it.
    final class GlobalPriorityAgreement {
        var code: String
        var name: String
        var version: Int
        var ownerID: String
        var maximum: Double
        var status: GlobalPriorityAgreementStatus

        init(code: String, name: String, version: Int, ownerID: String, maximum: Double, status: GlobalPriorityAgreementStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.ownerID = ownerID
            self.maximum = maximum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalPriorityAgreementStatus) -> Bool {
            switch status {
            case .planned:
                return next == GlobalPriorityAgreementStatus.inProgress
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == GlobalPriorityAgreementStatus.cancelled
            case .completed:
                return next == GlobalPriorityAgreementStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalPriorityAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global priority agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedExposure() -> Double {
            return ((Double(version) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> GlobalPriorityAgreement {
            return GlobalPriorityAgreement(
                code: code,
                name: name,
                version: version,
                ownerID: ownerID,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global priority agreement in status planned.
    static func newGlobalPriorityAgreement(_ code: String, name: String) -> GlobalPriorityAgreement {
        return GlobalPriorityAgreement(
            code: code,
            name: name,
            version: 0,
            ownerID: "",
            maximum: 0.0,
            status: GlobalPriorityAgreementStatus.planned
        )
    }
}
