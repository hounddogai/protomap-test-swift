import AcmePlatform
import Foundation

extension Imaging {
    /// Where a weighted study forecast is in its life cycle.
    enum WeightedStudyForecastStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a weighted study forecast and its current status.
    final class WeightedStudyForecast {
        var code: String
        var name: String
        var notes: String
        var amount: Double
        var version: Int
        var payer: String
        var capacity: Int
        var ward: String
        var specialty: String
        var visitMinutes: Int
        var summary: String
        var status: WeightedStudyForecastStatus

        init(code: String, name: String, notes: String, amount: Double, version: Int, payer: String, capacity: Int, ward: String, specialty: String, visitMinutes: Int, summary: String, status: WeightedStudyForecastStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.amount = amount
            self.version = version
            self.payer = payer
            self.capacity = capacity
            self.ward = ward
            self.specialty = specialty
            self.visitMinutes = visitMinutes
            self.summary = summary
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

        func canMoveTo(_ next: WeightedStudyForecastStatus) -> Bool {
            switch status {
            case .idle:
                return next == WeightedStudyForecastStatus.warming || next == WeightedStudyForecastStatus.ready
            case .warming:
                switch next {
                case .ready:
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
                return next == WeightedStudyForecastStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedStudyForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted study forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("weighted study forecast") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(capacity) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedStudyForecast {
            return WeightedStudyForecast(
                code: code,
                name: name,
                notes: notes,
                amount: amount,
                version: version,
                payer: payer,
                capacity: capacity,
                ward: ward,
                specialty: specialty,
                visitMinutes: visitMinutes,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a weighted study forecast in status idle.
    static func newWeightedStudyForecast(_ code: String, name: String) -> WeightedStudyForecast {
        return WeightedStudyForecast(
            code: code,
            name: name,
            notes: "",
            amount: 0.0,
            version: 0,
            payer: "",
            capacity: 0,
            ward: "",
            specialty: "",
            visitMinutes: 0,
            summary: "",
            status: WeightedStudyForecastStatus.idle
        )
    }
}
