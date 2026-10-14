import AcmePlatform
import Foundation

extension Labs {
    /// Where a weighted accession variance is in its life cycle.
    enum WeightedAccessionVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A weighted accession variance as the accession team keeps it.
    final class WeightedAccessionVariance {
        var code: String
        var name: String
        var externalRef: String
        var allergy: String
        var unit: String
        var score: Double
        var status: WeightedAccessionVarianceStatus

        init(code: String, name: String, externalRef: String, allergy: String, unit: String, score: Double, status: WeightedAccessionVarianceStatus) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.allergy = allergy
            self.unit = unit
            self.score = score
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

        func canMoveTo(_ next: WeightedAccessionVarianceStatus) -> Bool {
            switch status {
            case .new:
                return next == WeightedAccessionVarianceStatus.running
            case .queued:
                return next == WeightedAccessionVarianceStatus.failed
            case .running:
                return next == WeightedAccessionVarianceStatus.done || next == WeightedAccessionVarianceStatus.failed
            case .done:
                return next == WeightedAccessionVarianceStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedAccessionVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted accession variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> WeightedAccessionVariance {
            return WeightedAccessionVariance(
                code: code,
                name: name,
                externalRef: externalRef,
                allergy: allergy,
                unit: unit,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a weighted accession variance in status new.
    static func newWeightedAccessionVariance(_ code: String, name: String) -> WeightedAccessionVariance {
        return WeightedAccessionVariance(
            code: code,
            name: name,
            externalRef: "",
            allergy: "",
            unit: "",
            score: 0.0,
            status: WeightedAccessionVarianceStatus.new
        )
    }
}
