import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a capped statement forecast is in its life cycle.
    enum CappedStatementForecastStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One capped statement forecast, with what the planners need to act on it.
    final class CappedStatementForecast {
        var code: String
        var name: String
        var segment: String
        var maximum: Double
        var ceiling: Double
        var procedureCode: String
        var ownerID: String
        var batchSize: Int
        var minimum: Double
        var patientRef: String
        var status: CappedStatementForecastStatus

        init(code: String, name: String, segment: String, maximum: Double, ceiling: Double, procedureCode: String, ownerID: String, batchSize: Int, minimum: Double, patientRef: String, status: CappedStatementForecastStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.maximum = maximum
            self.ceiling = ceiling
            self.procedureCode = procedureCode
            self.ownerID = ownerID
            self.batchSize = batchSize
            self.minimum = minimum
            self.patientRef = patientRef
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

        func canMoveTo(_ next: CappedStatementForecastStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == CappedStatementForecastStatus.draining || next == CappedStatementForecastStatus.stopped
            case .draining:
                return next == CappedStatementForecastStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedStatementForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped statement forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedLoad() -> Double {
            return ((maximum - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> CappedStatementForecast {
            return CappedStatementForecast(
                code: code,
                name: name,
                segment: segment,
                maximum: maximum,
                ceiling: ceiling,
                procedureCode: procedureCode,
                ownerID: ownerID,
                batchSize: batchSize,
                minimum: minimum,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a capped statement forecast in status idle.
    static func newCappedStatementForecast(_ code: String, name: String) -> CappedStatementForecast {
        return CappedStatementForecast(
            code: code,
            name: name,
            segment: "",
            maximum: 0.0,
            ceiling: 0.0,
            procedureCode: "",
            ownerID: "",
            batchSize: 0,
            minimum: 0.0,
            patientRef: "",
            status: CappedStatementForecastStatus.idle
        )
    }
}
