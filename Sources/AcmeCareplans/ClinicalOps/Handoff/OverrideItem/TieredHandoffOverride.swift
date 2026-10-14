import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a tiered handoff override is in its life cycle.
    enum TieredHandoffOverrideStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A tiered handoff override. Its code is unique within a tenant.
    final class TieredHandoffOverride {
        var code: String
        var title: String
        var batchSize: Int
        var timezone: String
        var weight: Double
        var procedureCode: String
        var minimum: Double
        var bed: String
        var status: TieredHandoffOverrideStatus

        init(code: String, title: String, batchSize: Int, timezone: String, weight: Double, procedureCode: String, minimum: Double, bed: String, status: TieredHandoffOverrideStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.timezone = timezone
            self.weight = weight
            self.procedureCode = procedureCode
            self.minimum = minimum
            self.bed = bed
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

        func canMoveTo(_ next: TieredHandoffOverrideStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == TieredHandoffOverrideStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredHandoffOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered handoff override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("tiered handoff override") \(code)"
        }

        func adjustedValue() -> Double {
            return (weight * minimum * 100).rounded() / 100
        }

        func copyValue() -> TieredHandoffOverride {
            return TieredHandoffOverride(
                code: code,
                title: title,
                batchSize: batchSize,
                timezone: timezone,
                weight: weight,
                procedureCode: procedureCode,
                minimum: minimum,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered handoff override in status proposed.
    static func newTieredHandoffOverride(_ code: String, title: String) -> TieredHandoffOverride {
        return TieredHandoffOverride(
            code: code,
            title: title,
            batchSize: 0,
            timezone: "",
            weight: 0.0,
            procedureCode: "",
            minimum: 0.0,
            bed: "",
            status: TieredHandoffOverrideStatus.proposed
        )
    }
}
