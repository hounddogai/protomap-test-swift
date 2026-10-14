import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift score is in its life cycle.
    enum ShiftScoreStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One shift score, with what the planners need to act on it.
    final class ShiftScore {
        var code: String
        var title: String
        var score: Double
        var limit: Int
        var floorValue: Double
        var name: String
        var ward: String
        var status: ShiftScoreStatus

        init(code: String, title: String, score: Double, limit: Int, floorValue: Double, name: String, ward: String, status: ShiftScoreStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.limit = limit
            self.floorValue = floorValue
            self.name = name
            self.ward = ward
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

        func canMoveTo(_ next: ShiftScoreStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ShiftScoreStatus.approved
            case .approved:
                switch next {
                case .rejected, .withdrawn:
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

        func moveTo(_ next: ShiftScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedValue() -> Double {
            return ((score - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> ShiftScore {
            return ShiftScore(
                code: code,
                title: title,
                score: score,
                limit: limit,
                floorValue: floorValue,
                name: name,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a shift score in status proposed.
    static func newShiftScore(_ code: String, title: String) -> ShiftScore {
        return ShiftScore(
            code: code,
            title: title,
            score: 0.0,
            limit: 0,
            floorValue: 0.0,
            name: "",
            ward: "",
            status: ShiftScoreStatus.proposed
        )
    }
}
