import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a weighted isolation variance is in its life cycle.
    enum WeightedIsolationVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One weighted isolation variance, with what the planners need to act on it.
    final class WeightedIsolationVariance {
        var code: String
        var title: String
        var clinicianID: String
        var label: String
        var dosageMg: Double
        var status: WeightedIsolationVarianceStatus

        init(code: String, title: String, clinicianID: String, label: String, dosageMg: Double, status: WeightedIsolationVarianceStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.label = label
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: WeightedIsolationVarianceStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
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

        func moveTo(_ next: WeightedIsolationVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted isolation variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> WeightedIsolationVariance {
            return WeightedIsolationVariance(
                code: code,
                title: title,
                clinicianID: clinicianID,
                label: label,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a weighted isolation variance in status new.
    static func newWeightedIsolationVariance(_ code: String, title: String) -> WeightedIsolationVariance {
        return WeightedIsolationVariance(
            code: code,
            title: title,
            clinicianID: "",
            label: "",
            dosageMg: 0.0,
            status: WeightedIsolationVarianceStatus.new
        )
    }
}
