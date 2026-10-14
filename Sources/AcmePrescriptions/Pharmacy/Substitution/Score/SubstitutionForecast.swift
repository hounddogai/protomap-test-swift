import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution forecast is in its life cycle.
    enum SubstitutionForecastStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One substitution forecast, with what the planners need to act on it.
    final class SubstitutionForecast {
        var code: String
        var name: String
        var windowDays: Int
        var discount: Double
        var ratio: Double
        var cost: Double
        var encounterID: String
        var bed: String
        var payer: String
        var status: SubstitutionForecastStatus

        init(code: String, name: String, windowDays: Int, discount: Double, ratio: Double, cost: Double, encounterID: String, bed: String, payer: String, status: SubstitutionForecastStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.discount = discount
            self.ratio = ratio
            self.cost = cost
            self.encounterID = encounterID
            self.bed = bed
            self.payer = payer
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

        func canMoveTo(_ next: SubstitutionForecastStatus) -> Bool {
            switch status {
            case .idle:
                return next == SubstitutionForecastStatus.ready
            case .warming:
                return next == SubstitutionForecastStatus.ready || next == SubstitutionForecastStatus.draining
            case .ready:
                return next == SubstitutionForecastStatus.draining || next == SubstitutionForecastStatus.stopped
            case .draining:
                return next == SubstitutionForecastStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveVolume() -> Double {
            return ((discount + ratio) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionForecast {
            return SubstitutionForecast(
                code: code,
                name: name,
                windowDays: windowDays,
                discount: discount,
                ratio: ratio,
                cost: cost,
                encounterID: encounterID,
                bed: bed,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a substitution forecast in status idle.
    static func newSubstitutionForecast(_ code: String, name: String) -> SubstitutionForecast {
        return SubstitutionForecast(
            code: code,
            name: name,
            windowDays: 0,
            discount: 0.0,
            ratio: 0.0,
            cost: 0.0,
            encounterID: "",
            bed: "",
            payer: "",
            status: SubstitutionForecastStatus.idle
        )
    }
}
