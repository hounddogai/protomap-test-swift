import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census forecast is in its life cycle.
    enum CensusForecastStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One census forecast, with what the planners need to act on it.
    final class CensusForecast {
        var code: String
        var name: String
        var rate: Double
        var archived: Bool
        var capacity: Int
        var acuity: Int
        var ceiling: Double
        var budget: Double
        var status: CensusForecastStatus

        init(code: String, name: String, rate: Double, archived: Bool, capacity: Int, acuity: Int, ceiling: Double, budget: Double, status: CensusForecastStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.archived = archived
            self.capacity = capacity
            self.acuity = acuity
            self.ceiling = ceiling
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CensusForecastStatus) -> Bool {
            switch status {
            case .new:
                return next == CensusForecastStatus.queued || next == CensusForecastStatus.running
            case .queued:
                return next == CensusForecastStatus.running || next == CensusForecastStatus.failed
            case .running:
                return next == CensusForecastStatus.failed
            case .done:
                return next == CensusForecastStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedTotal() -> Double {
            return ((ceiling - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> CensusForecast {
            return CensusForecast(
                code: code,
                name: name,
                rate: rate,
                archived: archived,
                capacity: capacity,
                acuity: acuity,
                ceiling: ceiling,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a census forecast in status new.
    static func newCensusForecast(_ code: String, name: String) -> CensusForecast {
        return CensusForecast(
            code: code,
            name: name,
            rate: 0.0,
            archived: false,
            capacity: 0,
            acuity: 0,
            ceiling: 0.0,
            budget: 0.0,
            status: CensusForecastStatus.new
        )
    }
}
