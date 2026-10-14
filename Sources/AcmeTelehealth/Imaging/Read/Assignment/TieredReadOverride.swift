import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered read override is in its life cycle.
    enum TieredReadOverrideStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A tiered read override as the read team keeps it.
    final class TieredReadOverride {
        var code: String
        var label: String
        var bed: String
        var encounterID: String
        var ratio: Double
        var procedureCode: String
        var description: String
        var batchSize: Int
        var priority: Int
        var unit: String
        var status: TieredReadOverrideStatus

        init(code: String, label: String, bed: String, encounterID: String, ratio: Double, procedureCode: String, description: String, batchSize: Int, priority: Int, unit: String, status: TieredReadOverrideStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.encounterID = encounterID
            self.ratio = ratio
            self.procedureCode = procedureCode
            self.description = description
            self.batchSize = batchSize
            self.priority = priority
            self.unit = unit
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

        func canMoveTo(_ next: TieredReadOverrideStatus) -> Bool {
            switch status {
            case .requested:
                return next == TieredReadOverrideStatus.granted
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == TieredReadOverrideStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredReadOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered read override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedLoad() -> Double {
            return ((ratio + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> TieredReadOverride {
            return TieredReadOverride(
                code: code,
                label: label,
                bed: bed,
                encounterID: encounterID,
                ratio: ratio,
                procedureCode: procedureCode,
                description: description,
                batchSize: batchSize,
                priority: priority,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a tiered read override in status requested.
    static func newTieredReadOverride(_ code: String, label: String) -> TieredReadOverride {
        return TieredReadOverride(
            code: code,
            label: label,
            bed: "",
            encounterID: "",
            ratio: 0.0,
            procedureCode: "",
            description: "",
            batchSize: 0,
            priority: 0,
            unit: "",
            status: TieredReadOverrideStatus.requested
        )
    }
}
