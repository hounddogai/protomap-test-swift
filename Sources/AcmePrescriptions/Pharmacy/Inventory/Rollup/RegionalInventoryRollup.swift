import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a regional inventory rollup is in its life cycle.
    enum RegionalInventoryRollupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A regional inventory rollup. Its code is unique within a tenant.
    final class RegionalInventoryRollup {
        var code: String
        var label: String
        var sequence: Int
        var phone: String
        var source: String
        var score: Double
        var description: String
        var status: RegionalInventoryRollupStatus

        init(code: String, label: String, sequence: Int, phone: String, source: String, score: Double, description: String, status: RegionalInventoryRollupStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.phone = phone
            self.source = source
            self.score = score
            self.description = description
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

        func canMoveTo(_ next: RegionalInventoryRollupStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == RegionalInventoryRollupStatus.completed || next == RegionalInventoryRollupStatus.cancelled
            case .inProgress:
                return next == RegionalInventoryRollupStatus.cancelled
            case .completed:
                return next == RegionalInventoryRollupStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalInventoryRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional inventory rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("regional inventory rollup") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(sequence) + score) * 100).rounded() / 100
        }

        func copyValue() -> RegionalInventoryRollup {
            return RegionalInventoryRollup(
                code: code,
                label: label,
                sequence: sequence,
                phone: phone,
                source: source,
                score: score,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a regional inventory rollup in status planned.
    static func newRegionalInventoryRollup(_ code: String, label: String) -> RegionalInventoryRollup {
        return RegionalInventoryRollup(
            code: code,
            label: label,
            sequence: 0,
            phone: "",
            source: "",
            score: 0.0,
            description: "",
            status: RegionalInventoryRollupStatus.planned
        )
    }
}
