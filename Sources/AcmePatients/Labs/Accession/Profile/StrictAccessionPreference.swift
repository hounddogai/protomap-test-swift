import AcmePlatform
import Foundation

extension Labs {
    /// Where a strict accession preference is in its life cycle.
    enum StrictAccessionPreferenceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a strict accession preference and its current status.
    final class StrictAccessionPreference {
        var code: String
        var label: String
        var batchSize: Int
        var maximum: Double
        var minimum: Double
        var region: String
        var name: String
        var threshold: Double
        var status: StrictAccessionPreferenceStatus

        init(code: String, label: String, batchSize: Int, maximum: Double, minimum: Double, region: String, name: String, threshold: Double, status: StrictAccessionPreferenceStatus) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.maximum = maximum
            self.minimum = minimum
            self.region = region
            self.name = name
            self.threshold = threshold
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

        func canMoveTo(_ next: StrictAccessionPreferenceStatus) -> Bool {
            switch status {
            case .idle:
                return next == StrictAccessionPreferenceStatus.warming || next == StrictAccessionPreferenceStatus.stopped
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == StrictAccessionPreferenceStatus.draining || next == StrictAccessionPreferenceStatus.stopped
            case .draining:
                return next == StrictAccessionPreferenceStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictAccessionPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict accession preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveValue() -> Double {
            return (minimum * maximum * 100).rounded() / 100
        }

        func copyValue() -> StrictAccessionPreference {
            return StrictAccessionPreference(
                code: code,
                label: label,
                batchSize: batchSize,
                maximum: maximum,
                minimum: minimum,
                region: region,
                name: name,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a strict accession preference in status idle.
    static func newStrictAccessionPreference(_ code: String, label: String) -> StrictAccessionPreference {
        return StrictAccessionPreference(
            code: code,
            label: label,
            batchSize: 0,
            maximum: 0.0,
            minimum: 0.0,
            region: "",
            name: "",
            threshold: 0.0,
            status: StrictAccessionPreferenceStatus.idle
        )
    }
}
