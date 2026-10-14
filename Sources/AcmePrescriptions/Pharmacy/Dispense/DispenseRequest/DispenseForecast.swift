import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense forecast is in its life cycle.
    enum DispenseForecastStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a dispense forecast and its current status.
    final class DispenseForecast {
        var code: String
        var name: String
        var rate: Double
        var facility: String
        var reviewer: String
        var endsAt: Int
        var bed: String
        var copay: Double
        var status: DispenseForecastStatus

        init(code: String, name: String, rate: Double, facility: String, reviewer: String, endsAt: Int, bed: String, copay: Double, status: DispenseForecastStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.facility = facility
            self.reviewer = reviewer
            self.endsAt = endsAt
            self.bed = bed
            self.copay = copay
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

        func canMoveTo(_ next: DispenseForecastStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == DispenseForecastStatus.withdrawn
            case .rejected:
                return next == DispenseForecastStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispenseForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("dispense forecast") \(code)"
        }

        func weightedTotal() -> Double {
            return ((rate + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> DispenseForecast {
            return DispenseForecast(
                code: code,
                name: name,
                rate: rate,
                facility: facility,
                reviewer: reviewer,
                endsAt: endsAt,
                bed: bed,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a dispense forecast in status proposed.
    static func newDispenseForecast(_ code: String, name: String) -> DispenseForecast {
        return DispenseForecast(
            code: code,
            name: name,
            rate: 0.0,
            facility: "",
            reviewer: "",
            endsAt: 0,
            bed: "",
            copay: 0.0,
            status: DispenseForecastStatus.proposed
        )
    }
}
