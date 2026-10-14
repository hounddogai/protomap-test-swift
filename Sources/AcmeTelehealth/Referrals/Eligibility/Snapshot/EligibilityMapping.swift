import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility mapping is in its life cycle.
    enum EligibilityMappingStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A eligibility mapping as the eligibility team keeps it.
    final class EligibilityMapping {
        var code: String
        var name: String
        var ceiling: Double
        var weight: Double
        var updatedAt: Int
        var cost: Double
        var reviewer: String
        var budget: Double
        var minimum: Double
        var status: EligibilityMappingStatus

        init(code: String, name: String, ceiling: Double, weight: Double, updatedAt: Int, cost: Double, reviewer: String, budget: Double, minimum: Double, status: EligibilityMappingStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.weight = weight
            self.updatedAt = updatedAt
            self.cost = cost
            self.reviewer = reviewer
            self.budget = budget
            self.minimum = minimum
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

        func canMoveTo(_ next: EligibilityMappingStatus) -> Bool {
            switch status {
            case .new:
                return next == EligibilityMappingStatus.queued || next == EligibilityMappingStatus.running
            case .queued:
                return next == EligibilityMappingStatus.failed
            case .running:
                return next == EligibilityMappingStatus.done || next == EligibilityMappingStatus.failed
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

        func moveTo(_ next: EligibilityMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedExposure() -> Double {
            return ((weight + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityMapping {
            return EligibilityMapping(
                code: code,
                name: name,
                ceiling: ceiling,
                weight: weight,
                updatedAt: updatedAt,
                cost: cost,
                reviewer: reviewer,
                budget: budget,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a eligibility mapping in status new.
    static func newEligibilityMapping(_ code: String, name: String) -> EligibilityMapping {
        return EligibilityMapping(
            code: code,
            name: name,
            ceiling: 0.0,
            weight: 0.0,
            updatedAt: 0,
            cost: 0.0,
            reviewer: "",
            budget: 0.0,
            minimum: 0.0,
            status: EligibilityMappingStatus.new
        )
    }
}
