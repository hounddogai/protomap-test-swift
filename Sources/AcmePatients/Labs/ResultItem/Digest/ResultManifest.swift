import AcmePlatform
import Foundation

extension Labs {
    /// Where a result manifest is in its life cycle.
    enum ResultManifestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One result manifest, with what the planners need to act on it.
    final class ResultManifest {
        var code: String
        var label: String
        var externalRef: String
        var ratio: Double
        var priority: Int
        var ward: String
        var batchSize: Int
        var maximum: Double
        var status: ResultManifestStatus

        init(code: String, label: String, externalRef: String, ratio: Double, priority: Int, ward: String, batchSize: Int, maximum: Double, status: ResultManifestStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.ratio = ratio
            self.priority = priority
            self.ward = ward
            self.batchSize = batchSize
            self.maximum = maximum
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

        func canMoveTo(_ next: ResultManifestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ResultManifestStatus.retired
            case .published:
                return next == ResultManifestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedVolume() -> Double {
            return ((Double(priority) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> ResultManifest {
            return ResultManifest(
                code: code,
                label: label,
                externalRef: externalRef,
                ratio: ratio,
                priority: priority,
                ward: ward,
                batchSize: batchSize,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a result manifest in status created.
    static func newResultManifest(_ code: String, label: String) -> ResultManifest {
        return ResultManifest(
            code: code,
            label: label,
            externalRef: "",
            ratio: 0.0,
            priority: 0,
            ward: "",
            batchSize: 0,
            maximum: 0.0,
            status: ResultManifestStatus.created
        )
    }
}
