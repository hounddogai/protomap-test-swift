import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a default task record is in its life cycle.
    enum DefaultTaskRecordStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a default task record and its current status.
    final class DefaultTaskRecord {
        var code: String
        var label: String
        var minimum: Double
        var graceDays: Int
        var diagnosisCode: String
        var maximum: Double
        var region: String
        var category: String
        var status: DefaultTaskRecordStatus

        init(code: String, label: String, minimum: Double, graceDays: Int, diagnosisCode: String, maximum: Double, region: String, category: String, status: DefaultTaskRecordStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.graceDays = graceDays
            self.diagnosisCode = diagnosisCode
            self.maximum = maximum
            self.region = region
            self.category = category
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

        func canMoveTo(_ next: DefaultTaskRecordStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == DefaultTaskRecordStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultTaskRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default task record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveVolume() -> Double {
            return ((Double(graceDays) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> DefaultTaskRecord {
            return DefaultTaskRecord(
                code: code,
                label: label,
                minimum: minimum,
                graceDays: graceDays,
                diagnosisCode: diagnosisCode,
                maximum: maximum,
                region: region,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a default task record in status new.
    static func newDefaultTaskRecord(_ code: String, label: String) -> DefaultTaskRecord {
        return DefaultTaskRecord(
            code: code,
            label: label,
            minimum: 0.0,
            graceDays: 0,
            diagnosisCode: "",
            maximum: 0.0,
            region: "",
            category: "",
            status: DefaultTaskRecordStatus.new
        )
    }
}
