import AcmePlatform
import Foundation

extension Staffing {
    /// Where a weighted credential variance is in its life cycle.
    enum WeightedCredentialVarianceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A weighted credential variance as the credential team keeps it.
    final class WeightedCredentialVariance {
        var code: String
        var label: String
        var specialty: String
        var encounterID: String
        var graceDays: Int
        var ratio: Double
        var acuity: Int
        var floorValue: Double
        var maximum: Double
        var batchSize: Int
        var sequence: Int
        var status: WeightedCredentialVarianceStatus

        init(code: String, label: String, specialty: String, encounterID: String, graceDays: Int, ratio: Double, acuity: Int, floorValue: Double, maximum: Double, batchSize: Int, sequence: Int, status: WeightedCredentialVarianceStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.encounterID = encounterID
            self.graceDays = graceDays
            self.ratio = ratio
            self.acuity = acuity
            self.floorValue = floorValue
            self.maximum = maximum
            self.batchSize = batchSize
            self.sequence = sequence
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedCredentialVarianceStatus) -> Bool {
            switch status {
            case .idle:
                return next == WeightedCredentialVarianceStatus.stopped
            case .warming:
                return next == WeightedCredentialVarianceStatus.draining
            case .ready:
                return next == WeightedCredentialVarianceStatus.draining || next == WeightedCredentialVarianceStatus.stopped
            case .draining:
                return next == WeightedCredentialVarianceStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedCredentialVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted credential variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedTotal() -> Double {
            return ((Double(batchSize) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedCredentialVariance {
            return WeightedCredentialVariance(
                code: code,
                label: label,
                specialty: specialty,
                encounterID: encounterID,
                graceDays: graceDays,
                ratio: ratio,
                acuity: acuity,
                floorValue: floorValue,
                maximum: maximum,
                batchSize: batchSize,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted credential variance in status idle.
    static func newWeightedCredentialVariance(_ code: String, label: String) -> WeightedCredentialVariance {
        return WeightedCredentialVariance(
            code: code,
            label: label,
            specialty: "",
            encounterID: "",
            graceDays: 0,
            ratio: 0.0,
            acuity: 0,
            floorValue: 0.0,
            maximum: 0.0,
            batchSize: 0,
            sequence: 0,
            status: WeightedCredentialVarianceStatus.idle
        )
    }
}
