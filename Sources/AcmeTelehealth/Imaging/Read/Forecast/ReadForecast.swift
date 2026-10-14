import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read forecast is in its life cycle.
    enum ReadForecastStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One read forecast, with what the planners need to act on it.
    final class ReadForecast {
        var code: String
        var label: String
        var visitMinutes: Int
        var patientRef: String
        var ownerID: String
        var status: ReadForecastStatus

        init(code: String, label: String, visitMinutes: Int, patientRef: String, ownerID: String, status: ReadForecastStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.patientRef = patientRef
            self.ownerID = ownerID
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

        func canMoveTo(_ next: ReadForecastStatus) -> Bool {
            switch status {
            case .idle:
                return next == ReadForecastStatus.warming || next == ReadForecastStatus.draining
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
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ReadForecastStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(visitMinutes)
        }

        func copyValue() -> ReadForecast {
            return ReadForecast(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                patientRef: patientRef,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a read forecast in status idle.
    static func newReadForecast(_ code: String, label: String) -> ReadForecast {
        return ReadForecast(
            code: code,
            label: label,
            visitMinutes: 0,
            patientRef: "",
            ownerID: "",
            status: ReadForecastStatus.idle
        )
    }
}
