import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending risk score rollup is in its life cycle.
    enum PendingRiskScoreRollupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a pending risk score rollup and its current status.
    final class PendingRiskScoreRollup {
        var code: String
        var name: String
        var dosageMg: Double
        var quantity: Int
        var bed: String
        var refills: Int
        var maximum: Double
        var category: String
        var minimum: Double
        var budget: Double
        var status: PendingRiskScoreRollupStatus

        init(code: String, name: String, dosageMg: Double, quantity: Int, bed: String, refills: Int, maximum: Double, category: String, minimum: Double, budget: Double, status: PendingRiskScoreRollupStatus) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.quantity = quantity
            self.bed = bed
            self.refills = refills
            self.maximum = maximum
            self.category = category
            self.minimum = minimum
            self.budget = budget
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

        func canMoveTo(_ next: PendingRiskScoreRollupStatus) -> Bool {
            switch status {
            case .new:
                return next == PendingRiskScoreRollupStatus.running || next == PendingRiskScoreRollupStatus.done
            case .queued:
                return next == PendingRiskScoreRollupStatus.done
            case .running:
                return next == PendingRiskScoreRollupStatus.done || next == PendingRiskScoreRollupStatus.failed
            case .done:
                return next == PendingRiskScoreRollupStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingRiskScoreRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending risk score rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending risk score rollup") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((Double(refills) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> PendingRiskScoreRollup {
            return PendingRiskScoreRollup(
                code: code,
                name: name,
                dosageMg: dosageMg,
                quantity: quantity,
                bed: bed,
                refills: refills,
                maximum: maximum,
                category: category,
                minimum: minimum,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a pending risk score rollup in status new.
    static func newPendingRiskScoreRollup(_ code: String, name: String) -> PendingRiskScoreRollup {
        return PendingRiskScoreRollup(
            code: code,
            name: name,
            dosageMg: 0.0,
            quantity: 0,
            bed: "",
            refills: 0,
            maximum: 0.0,
            category: "",
            minimum: 0.0,
            budget: 0.0,
            status: PendingRiskScoreRollupStatus.new
        )
    }
}
