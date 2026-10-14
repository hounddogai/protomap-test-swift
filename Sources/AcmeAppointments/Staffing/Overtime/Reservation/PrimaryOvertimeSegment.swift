import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary overtime segment is in its life cycle.
    enum PrimaryOvertimeSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a primary overtime segment and its current status.
    final class PrimaryOvertimeSegment {
        var code: String
        var name: String
        var durationMinutes: Int
        var quantity: Int
        var startsAt: Int
        var status: PrimaryOvertimeSegmentStatus

        init(code: String, name: String, durationMinutes: Int, quantity: Int, startsAt: Int, status: PrimaryOvertimeSegmentStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.quantity = quantity
            self.startsAt = startsAt
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

        func canMoveTo(_ next: PrimaryOvertimeSegmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == PrimaryOvertimeSegmentStatus.pending || next == PrimaryOvertimeSegmentStatus.suspended
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PrimaryOvertimeSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary overtime segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveLoad() -> Double {
            return (Double(durationMinutes) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryOvertimeSegment {
            return PrimaryOvertimeSegment(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                quantity: quantity,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary overtime segment in status draft.
    static func newPrimaryOvertimeSegment(_ code: String, name: String) -> PrimaryOvertimeSegment {
        return PrimaryOvertimeSegment(
            code: code,
            name: name,
            durationMinutes: 0,
            quantity: 0,
            startsAt: 0,
            status: PrimaryOvertimeSegmentStatus.draft
        )
    }
}
