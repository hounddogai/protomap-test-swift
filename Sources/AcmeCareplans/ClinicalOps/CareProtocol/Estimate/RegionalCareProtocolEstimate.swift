import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional care protocol estimate is in its life cycle.
    enum RegionalCareProtocolEstimateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One regional care protocol estimate, with what the planners need to act on it.
    final class RegionalCareProtocolEstimate {
        var code: String
        var label: String
        var unit: String
        var copay: Double
        var batchSize: Int
        var weight: Double
        var patientRef: String
        var version: Int
        var specialty: String
        var status: RegionalCareProtocolEstimateStatus

        init(code: String, label: String, unit: String, copay: Double, batchSize: Int, weight: Double, patientRef: String, version: Int, specialty: String, status: RegionalCareProtocolEstimateStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.copay = copay
            self.batchSize = batchSize
            self.weight = weight
            self.patientRef = patientRef
            self.version = version
            self.specialty = specialty
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

        func canMoveTo(_ next: RegionalCareProtocolEstimateStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == RegionalCareProtocolEstimateStatus.completed
            case .completed:
                return next == RegionalCareProtocolEstimateStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalCareProtocolEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional care protocol estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("regional care protocol estimate") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(batchSize) - copay) * 100).rounded() / 100
        }

        func copyValue() -> RegionalCareProtocolEstimate {
            return RegionalCareProtocolEstimate(
                code: code,
                label: label,
                unit: unit,
                copay: copay,
                batchSize: batchSize,
                weight: weight,
                patientRef: patientRef,
                version: version,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a regional care protocol estimate in status planned.
    static func newRegionalCareProtocolEstimate(_ code: String, label: String) -> RegionalCareProtocolEstimate {
        return RegionalCareProtocolEstimate(
            code: code,
            label: label,
            unit: "",
            copay: 0.0,
            batchSize: 0,
            weight: 0.0,
            patientRef: "",
            version: 0,
            specialty: "",
            status: RegionalCareProtocolEstimateStatus.planned
        )
    }
}
