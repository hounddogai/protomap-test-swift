import AcmePlatform
import Foundation

extension Staffing {
    /// Where a tiered shift score is in its life cycle.
    enum TieredShiftScoreStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a tiered shift score and its current status.
    final class TieredShiftScore {
        var code: String
        var name: String
        var maximum: Double
        var notes: String
        var limit: Int
        var ownerID: String
        var acuity: Int
        var title: String
        var refills: Int
        var status: TieredShiftScoreStatus

        init(code: String, name: String, maximum: Double, notes: String, limit: Int, ownerID: String, acuity: Int, title: String, refills: Int, status: TieredShiftScoreStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.notes = notes
            self.limit = limit
            self.ownerID = ownerID
            self.acuity = acuity
            self.title = title
            self.refills = refills
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

        func canMoveTo(_ next: TieredShiftScoreStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: TieredShiftScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered shift score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedExposure() -> Double {
            return ((Double(limit) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> TieredShiftScore {
            return TieredShiftScore(
                code: code,
                name: name,
                maximum: maximum,
                notes: notes,
                limit: limit,
                ownerID: ownerID,
                acuity: acuity,
                title: title,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered shift score in status planned.
    static func newTieredShiftScore(_ code: String, name: String) -> TieredShiftScore {
        return TieredShiftScore(
            code: code,
            name: name,
            maximum: 0.0,
            notes: "",
            limit: 0,
            ownerID: "",
            acuity: 0,
            title: "",
            refills: 0,
            status: TieredShiftScoreStatus.planned
        )
    }
}
