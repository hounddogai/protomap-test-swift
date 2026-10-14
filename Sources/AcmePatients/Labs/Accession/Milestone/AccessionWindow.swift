import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession window is in its life cycle.
    enum AccessionWindowStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a accession window and its current status.
    final class AccessionWindow {
        var code: String
        var title: String
        var capacity: Int
        var active: Bool
        var durationMinutes: Int
        var minimum: Double
        var diagnosisCode: String
        var rate: Double
        var name: String
        var batchSize: Int
        var status: AccessionWindowStatus

        init(code: String, title: String, capacity: Int, active: Bool, durationMinutes: Int, minimum: Double, diagnosisCode: String, rate: Double, name: String, batchSize: Int, status: AccessionWindowStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.active = active
            self.durationMinutes = durationMinutes
            self.minimum = minimum
            self.diagnosisCode = diagnosisCode
            self.rate = rate
            self.name = name
            self.batchSize = batchSize
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

        func canMoveTo(_ next: AccessionWindowStatus) -> Bool {
            switch status {
            case .planned:
                return next == AccessionWindowStatus.completed
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == AccessionWindowStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("accession window") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(batchSize) + rate) * 100).rounded() / 100
        }

        func copyValue() -> AccessionWindow {
            return AccessionWindow(
                code: code,
                title: title,
                capacity: capacity,
                active: active,
                durationMinutes: durationMinutes,
                minimum: minimum,
                diagnosisCode: diagnosisCode,
                rate: rate,
                name: name,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a accession window in status planned.
    static func newAccessionWindow(_ code: String, title: String) -> AccessionWindow {
        return AccessionWindow(
            code: code,
            title: title,
            capacity: 0,
            active: false,
            durationMinutes: 0,
            minimum: 0.0,
            diagnosisCode: "",
            rate: 0.0,
            name: "",
            batchSize: 0,
            status: AccessionWindowStatus.planned
        )
    }
}
