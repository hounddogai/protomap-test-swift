import AcmePlatform
import Foundation

extension Consent {
    /// Where a weighted witness entry is in its life cycle.
    enum WeightedWitnessEntryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A weighted witness entry. Its code is unique within a tenant.
    final class WeightedWitnessEntry {
        var code: String
        var name: String
        var cost: Double
        var dosageMg: Double
        var endsAt: Int
        var startsAt: Int
        var attributes: [String: String]
        var maximum: Double
        var visitMinutes: Int
        var createdAt: Int
        var graceDays: Int
        var status: WeightedWitnessEntryStatus

        init(code: String, name: String, cost: Double, dosageMg: Double, endsAt: Int, startsAt: Int, attributes: [String: String], maximum: Double, visitMinutes: Int, createdAt: Int, graceDays: Int, status: WeightedWitnessEntryStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.dosageMg = dosageMg
            self.endsAt = endsAt
            self.startsAt = startsAt
            self.attributes = attributes
            self.maximum = maximum
            self.visitMinutes = visitMinutes
            self.createdAt = createdAt
            self.graceDays = graceDays
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

        func canMoveTo(_ next: WeightedWitnessEntryStatus) -> Bool {
            switch status {
            case .planned:
                return next == WeightedWitnessEntryStatus.completed || next == WeightedWitnessEntryStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == WeightedWitnessEntryStatus.completed || next == WeightedWitnessEntryStatus.cancelled
            case .completed:
                return next == WeightedWitnessEntryStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedWitnessEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted witness entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("weighted witness entry") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveVolume() -> Double {
            return (Double(visitMinutes) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> WeightedWitnessEntry {
            return WeightedWitnessEntry(
                code: code,
                name: name,
                cost: cost,
                dosageMg: dosageMg,
                endsAt: endsAt,
                startsAt: startsAt,
                attributes: attributes,
                maximum: maximum,
                visitMinutes: visitMinutes,
                createdAt: createdAt,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted witness entry in status planned.
    static func newWeightedWitnessEntry(_ code: String, name: String) -> WeightedWitnessEntry {
        return WeightedWitnessEntry(
            code: code,
            name: name,
            cost: 0.0,
            dosageMg: 0.0,
            endsAt: 0,
            startsAt: 0,
            attributes: [:],
            maximum: 0.0,
            visitMinutes: 0,
            createdAt: 0,
            graceDays: 0,
            status: WeightedWitnessEntryStatus.planned
        )
    }
}
