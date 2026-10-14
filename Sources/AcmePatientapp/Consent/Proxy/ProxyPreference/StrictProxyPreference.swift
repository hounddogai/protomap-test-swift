import AcmePlatform
import Foundation

extension Consent {
    /// Where a strict proxy preference is in its life cycle.
    enum StrictProxyPreferenceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A strict proxy preference. Its code is unique within a tenant.
    final class StrictProxyPreference {
        var code: String
        var label: String
        var retries: Int
        var sequence: Int
        var batchSize: Int
        var updatedAt: Int
        var unit: String
        var encounterID: String
        var amount: Double
        var diagnosisCode: String
        var status: StrictProxyPreferenceStatus

        init(code: String, label: String, retries: Int, sequence: Int, batchSize: Int, updatedAt: Int, unit: String, encounterID: String, amount: Double, diagnosisCode: String, status: StrictProxyPreferenceStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.sequence = sequence
            self.batchSize = batchSize
            self.updatedAt = updatedAt
            self.unit = unit
            self.encounterID = encounterID
            self.amount = amount
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: StrictProxyPreferenceStatus) -> Bool {
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
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == StrictProxyPreferenceStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictProxyPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict proxy preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedTotal() -> Double {
            return ((amount + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> StrictProxyPreference {
            return StrictProxyPreference(
                code: code,
                label: label,
                retries: retries,
                sequence: sequence,
                batchSize: batchSize,
                updatedAt: updatedAt,
                unit: unit,
                encounterID: encounterID,
                amount: amount,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a strict proxy preference in status planned.
    static func newStrictProxyPreference(_ code: String, label: String) -> StrictProxyPreference {
        return StrictProxyPreference(
            code: code,
            label: label,
            retries: 0,
            sequence: 0,
            batchSize: 0,
            updatedAt: 0,
            unit: "",
            encounterID: "",
            amount: 0.0,
            diagnosisCode: "",
            status: StrictProxyPreferenceStatus.planned
        )
    }
}
