import AcmePlatform
import Foundation

extension Referrals {
    /// Where a seasonal closure rule is in its life cycle.
    enum SeasonalClosureRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a seasonal closure rule and its current status.
    final class SeasonalClosureRule {
        var code: String
        var label: String
        var threshold: Double
        var discount: Double
        var weight: Double
        var margin: Double
        var pinned: Bool
        var clinicianID: String
        var ratio: Double
        var status: SeasonalClosureRuleStatus

        init(code: String, label: String, threshold: Double, discount: Double, weight: Double, margin: Double, pinned: Bool, clinicianID: String, ratio: Double, status: SeasonalClosureRuleStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.discount = discount
            self.weight = weight
            self.margin = margin
            self.pinned = pinned
            self.clinicianID = clinicianID
            self.ratio = ratio
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

        func canMoveTo(_ next: SeasonalClosureRuleStatus) -> Bool {
            switch status {
            case .new:
                return next == SeasonalClosureRuleStatus.queued
            case .queued:
                return next == SeasonalClosureRuleStatus.done || next == SeasonalClosureRuleStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == SeasonalClosureRuleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalClosureRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal closure rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedLoad() -> Double {
            return ((weight - threshold) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalClosureRule {
            return SeasonalClosureRule(
                code: code,
                label: label,
                threshold: threshold,
                discount: discount,
                weight: weight,
                margin: margin,
                pinned: pinned,
                clinicianID: clinicianID,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal closure rule in status new.
    static func newSeasonalClosureRule(_ code: String, label: String) -> SeasonalClosureRule {
        return SeasonalClosureRule(
            code: code,
            label: label,
            threshold: 0.0,
            discount: 0.0,
            weight: 0.0,
            margin: 0.0,
            pinned: false,
            clinicianID: "",
            ratio: 0.0,
            status: SeasonalClosureRuleStatus.new
        )
    }
}
