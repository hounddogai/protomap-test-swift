import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a weighted cleaning metric is in its life cycle.
    enum WeightedCleaningMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One weighted cleaning metric, with what the planners need to act on it.
    final class WeightedCleaningMetric {
        var code: String
        var name: String
        var category: String
        var capacity: Int
        var encounterID: String
        var ward: String
        var procedureCode: String
        var ratio: Double
        var status: WeightedCleaningMetricStatus

        init(code: String, name: String, category: String, capacity: Int, encounterID: String, ward: String, procedureCode: String, ratio: Double, status: WeightedCleaningMetricStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.capacity = capacity
            self.encounterID = encounterID
            self.ward = ward
            self.procedureCode = procedureCode
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedCleaningMetricStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == WeightedCleaningMetricStatus.revoked
            case .revoked:
                return next == WeightedCleaningMetricStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedCleaningMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted cleaning metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netValue() -> Double {
            return (ratio * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> WeightedCleaningMetric {
            return WeightedCleaningMetric(
                code: code,
                name: name,
                category: category,
                capacity: capacity,
                encounterID: encounterID,
                ward: ward,
                procedureCode: procedureCode,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a weighted cleaning metric in status requested.
    static func newWeightedCleaningMetric(_ code: String, name: String) -> WeightedCleaningMetric {
        return WeightedCleaningMetric(
            code: code,
            name: name,
            category: "",
            capacity: 0,
            encounterID: "",
            ward: "",
            procedureCode: "",
            ratio: 0.0,
            status: WeightedCleaningMetricStatus.requested
        )
    }
}
