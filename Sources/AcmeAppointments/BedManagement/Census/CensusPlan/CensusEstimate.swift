import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census estimate is in its life cycle.
    enum CensusEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A census estimate as the census team keeps it.
    final class CensusEstimate {
        var code: String
        var label: String
        var version: Int
        var visitMinutes: Int
        var weight: Double
        var diagnosisCode: String
        var batchSize: Int
        var revision: Int
        var attempts: Int
        var status: CensusEstimateStatus

        init(code: String, label: String, version: Int, visitMinutes: Int, weight: Double, diagnosisCode: String, batchSize: Int, revision: Int, attempts: Int, status: CensusEstimateStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.visitMinutes = visitMinutes
            self.weight = weight
            self.diagnosisCode = diagnosisCode
            self.batchSize = batchSize
            self.revision = revision
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CensusEstimateStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == CensusEstimateStatus.done
            case .running:
                return next == CensusEstimateStatus.done || next == CensusEstimateStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: CensusEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("census estimate") \(code)"
        }

        func projectedLoad() -> Double {
            return (Double(version) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> CensusEstimate {
            return CensusEstimate(
                code: code,
                label: label,
                version: version,
                visitMinutes: visitMinutes,
                weight: weight,
                diagnosisCode: diagnosisCode,
                batchSize: batchSize,
                revision: revision,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a census estimate in status new.
    static func newCensusEstimate(_ code: String, label: String) -> CensusEstimate {
        return CensusEstimate(
            code: code,
            label: label,
            version: 0,
            visitMinutes: 0,
            weight: 0.0,
            diagnosisCode: "",
            batchSize: 0,
            revision: 0,
            attempts: 0,
            status: CensusEstimateStatus.new
        )
    }
}
