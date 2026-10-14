import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen forecast is in its life cycle.
    enum SpecimenForecastStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A specimen forecast as the specimen team keeps it.
    final class SpecimenForecast {
        var code: String
        var label: String
        var weight: Double
        var sequence: Int
        var dosageMg: Double
        var title: String
        var score: Double
        var quantity: Int
        var segment: String
        var status: SpecimenForecastStatus

        init(code: String, label: String, weight: Double, sequence: Int, dosageMg: Double, title: String, score: Double, quantity: Int, segment: String, status: SpecimenForecastStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.sequence = sequence
            self.dosageMg = dosageMg
            self.title = title
            self.score = score
            self.quantity = quantity
            self.segment = segment
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

        func canMoveTo(_ next: SpecimenForecastStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
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
                return next == SpecimenForecastStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedTotal() -> Double {
            return (score * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> SpecimenForecast {
            return SpecimenForecast(
                code: code,
                label: label,
                weight: weight,
                sequence: sequence,
                dosageMg: dosageMg,
                title: title,
                score: score,
                quantity: quantity,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a specimen forecast in status planned.
    static func newSpecimenForecast(_ code: String, label: String) -> SpecimenForecast {
        return SpecimenForecast(
            code: code,
            label: label,
            weight: 0.0,
            sequence: 0,
            dosageMg: 0.0,
            title: "",
            score: 0.0,
            quantity: 0,
            segment: "",
            status: SpecimenForecastStatus.planned
        )
    }
}
