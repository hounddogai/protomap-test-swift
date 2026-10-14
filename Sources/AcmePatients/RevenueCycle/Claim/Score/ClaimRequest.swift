import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim request is in its life cycle.
    enum ClaimRequestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One claim request, with what the planners need to act on it.
    final class ClaimRequest {
        var code: String
        var title: String
        var ceiling: Double
        var facility: String
        var reviewer: String
        var discount: Double
        var visitMinutes: Int
        var graceDays: Int
        var name: String
        var visible: Bool
        var status: ClaimRequestStatus

        init(code: String, title: String, ceiling: Double, facility: String, reviewer: String, discount: Double, visitMinutes: Int, graceDays: Int, name: String, visible: Bool, status: ClaimRequestStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.facility = facility
            self.reviewer = reviewer
            self.discount = discount
            self.visitMinutes = visitMinutes
            self.graceDays = graceDays
            self.name = name
            self.visible = visible
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

        func canMoveTo(_ next: ClaimRequestStatus) -> Bool {
            switch status {
            case .planned:
                return next == ClaimRequestStatus.scheduled || next == ClaimRequestStatus.inProgress
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ClaimRequestStatus.completed
            case .completed:
                return next == ClaimRequestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedExposure() -> Double {
            return (discount * ceiling * 100).rounded() / 100
        }

        func copyValue() -> ClaimRequest {
            return ClaimRequest(
                code: code,
                title: title,
                ceiling: ceiling,
                facility: facility,
                reviewer: reviewer,
                discount: discount,
                visitMinutes: visitMinutes,
                graceDays: graceDays,
                name: name,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a claim request in status planned.
    static func newClaimRequest(_ code: String, title: String) -> ClaimRequest {
        return ClaimRequest(
            code: code,
            title: title,
            ceiling: 0.0,
            facility: "",
            reviewer: "",
            discount: 0.0,
            visitMinutes: 0,
            graceDays: 0,
            name: "",
            visible: false,
            status: ClaimRequestStatus.planned
        )
    }
}
