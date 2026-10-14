import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a weighted alert override is in its life cycle.
    enum WeightedAlertOverrideStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A weighted alert override. Its code is unique within a tenant.
    final class WeightedAlertOverride {
        var code: String
        var name: String
        var ceiling: Double
        var refills: Int
        var floorValue: Double
        var archived: Bool
        var unit: String
        var weight: Double
        var diagnosisCode: String
        var attempts: Int
        var endsAt: Int
        var status: WeightedAlertOverrideStatus

        init(code: String, name: String, ceiling: Double, refills: Int, floorValue: Double, archived: Bool, unit: String, weight: Double, diagnosisCode: String, attempts: Int, endsAt: Int, status: WeightedAlertOverrideStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.refills = refills
            self.floorValue = floorValue
            self.archived = archived
            self.unit = unit
            self.weight = weight
            self.diagnosisCode = diagnosisCode
            self.attempts = attempts
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedAlertOverrideStatus) -> Bool {
            switch status {
            case .created:
                return next == WeightedAlertOverrideStatus.published || next == WeightedAlertOverrideStatus.retired
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: WeightedAlertOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted alert override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedTotal() -> Double {
            return ((Double(refills) - weight) * 100).rounded() / 100
        }

        func copyValue() -> WeightedAlertOverride {
            return WeightedAlertOverride(
                code: code,
                name: name,
                ceiling: ceiling,
                refills: refills,
                floorValue: floorValue,
                archived: archived,
                unit: unit,
                weight: weight,
                diagnosisCode: diagnosisCode,
                attempts: attempts,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a weighted alert override in status created.
    static func newWeightedAlertOverride(_ code: String, name: String) -> WeightedAlertOverride {
        return WeightedAlertOverride(
            code: code,
            name: name,
            ceiling: 0.0,
            refills: 0,
            floorValue: 0.0,
            archived: false,
            unit: "",
            weight: 0.0,
            diagnosisCode: "",
            attempts: 0,
            endsAt: 0,
            status: WeightedAlertOverrideStatus.created
        )
    }
}
