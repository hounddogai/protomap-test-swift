import AcmePlatform
import Foundation

extension Imaging {
    /// Where a fallback worklist metric is in its life cycle.
    enum FallbackWorklistMetricStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a fallback worklist metric and its current status.
    final class FallbackWorklistMetric {
        var code: String
        var label: String
        var weight: Double
        var source: String
        var clinicianID: String
        var cost: Double
        var revision: Int
        var notes: String
        var status: FallbackWorklistMetricStatus

        init(code: String, label: String, weight: Double, source: String, clinicianID: String, cost: Double, revision: Int, notes: String, status: FallbackWorklistMetricStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.source = source
            self.clinicianID = clinicianID
            self.cost = cost
            self.revision = revision
            self.notes = notes
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

        func canMoveTo(_ next: FallbackWorklistMetricStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == FallbackWorklistMetricStatus.published || next == FallbackWorklistMetricStatus.retired
            case .published:
                return next == FallbackWorklistMetricStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackWorklistMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback worklist metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedTotal() -> Double {
            return (weight * cost * 100).rounded() / 100
        }

        func copyValue() -> FallbackWorklistMetric {
            return FallbackWorklistMetric(
                code: code,
                label: label,
                weight: weight,
                source: source,
                clinicianID: clinicianID,
                cost: cost,
                revision: revision,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a fallback worklist metric in status created.
    static func newFallbackWorklistMetric(_ code: String, label: String) -> FallbackWorklistMetric {
        return FallbackWorklistMetric(
            code: code,
            label: label,
            weight: 0.0,
            source: "",
            clinicianID: "",
            cost: 0.0,
            revision: 0,
            notes: "",
            status: FallbackWorklistMetricStatus.created
        )
    }
}
