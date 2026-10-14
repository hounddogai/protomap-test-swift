import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime segment is in its life cycle.
    enum OvertimeSegmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One overtime segment, with what the planners need to act on it.
    final class OvertimeSegment {
        var code: String
        var name: String
        var batchSize: Int
        var discount: Double
        var maximum: Double
        var margin: Double
        var status: OvertimeSegmentStatus

        init(code: String, name: String, batchSize: Int, discount: Double, maximum: Double, margin: Double, status: OvertimeSegmentStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.discount = discount
            self.maximum = maximum
            self.margin = margin
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

        func canMoveTo(_ next: OvertimeSegmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == OvertimeSegmentStatus.revoked
            case .revoked:
                return next == OvertimeSegmentStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimeSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedLoad() -> Double {
            return (margin * discount * 100).rounded() / 100
        }

        func copyValue() -> OvertimeSegment {
            return OvertimeSegment(
                code: code,
                name: name,
                batchSize: batchSize,
                discount: discount,
                maximum: maximum,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a overtime segment in status requested.
    static func newOvertimeSegment(_ code: String, name: String) -> OvertimeSegment {
        return OvertimeSegment(
            code: code,
            name: name,
            batchSize: 0,
            discount: 0.0,
            maximum: 0.0,
            margin: 0.0,
            status: OvertimeSegmentStatus.requested
        )
    }
}
