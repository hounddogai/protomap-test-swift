import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation threshold is in its life cycle.
    enum IsolationThresholdStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One isolation threshold, with what the planners need to act on it.
    final class IsolationThreshold {
        var code: String
        var name: String
        var contactEmail: String
        var bed: String
        var maximum: Double
        var threshold: Double
        var batchSize: Int
        var refills: Int
        var diagnosisCode: String
        var cost: Double
        var status: IsolationThresholdStatus

        init(code: String, name: String, contactEmail: String, bed: String, maximum: Double, threshold: Double, batchSize: Int, refills: Int, diagnosisCode: String, cost: Double, status: IsolationThresholdStatus) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.bed = bed
            self.maximum = maximum
            self.threshold = threshold
            self.batchSize = batchSize
            self.refills = refills
            self.diagnosisCode = diagnosisCode
            self.cost = cost
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

        func canMoveTo(_ next: IsolationThresholdStatus) -> Bool {
            switch status {
            case .planned:
                return next == IsolationThresholdStatus.inProgress
            case .scheduled:
                switch next {
                case .completed:
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
                return next == IsolationThresholdStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: IsolationThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("isolation threshold") \(code)"
        }

        func adjustedExposure() -> Double {
            return (threshold * maximum * 100).rounded() / 100
        }

        func copyValue() -> IsolationThreshold {
            return IsolationThreshold(
                code: code,
                name: name,
                contactEmail: contactEmail,
                bed: bed,
                maximum: maximum,
                threshold: threshold,
                batchSize: batchSize,
                refills: refills,
                diagnosisCode: diagnosisCode,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a isolation threshold in status planned.
    static func newIsolationThreshold(_ code: String, name: String) -> IsolationThreshold {
        return IsolationThreshold(
            code: code,
            name: name,
            contactEmail: "",
            bed: "",
            maximum: 0.0,
            threshold: 0.0,
            batchSize: 0,
            refills: 0,
            diagnosisCode: "",
            cost: 0.0,
            status: IsolationThresholdStatus.planned
        )
    }
}
