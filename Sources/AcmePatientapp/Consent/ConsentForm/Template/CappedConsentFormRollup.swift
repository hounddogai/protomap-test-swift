import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped consent form rollup is in its life cycle.
    enum CappedConsentFormRollupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a capped consent form rollup and its current status.
    final class CappedConsentFormRollup {
        var code: String
        var label: String
        var ceiling: Double
        var budget: Double
        var region: String
        var maximum: Double
        var attempts: Int
        var visitMinutes: Int
        var capacity: Int
        var status: CappedConsentFormRollupStatus

        init(code: String, label: String, ceiling: Double, budget: Double, region: String, maximum: Double, attempts: Int, visitMinutes: Int, capacity: Int, status: CappedConsentFormRollupStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.budget = budget
            self.region = region
            self.maximum = maximum
            self.attempts = attempts
            self.visitMinutes = visitMinutes
            self.capacity = capacity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedConsentFormRollupStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == CappedConsentFormRollupStatus.reopened || next == CappedConsentFormRollupStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: CappedConsentFormRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped consent form rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveLoad() -> Double {
            return (ceiling * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> CappedConsentFormRollup {
            return CappedConsentFormRollup(
                code: code,
                label: label,
                ceiling: ceiling,
                budget: budget,
                region: region,
                maximum: maximum,
                attempts: attempts,
                visitMinutes: visitMinutes,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a capped consent form rollup in status open.
    static func newCappedConsentFormRollup(_ code: String, label: String) -> CappedConsentFormRollup {
        return CappedConsentFormRollup(
            code: code,
            label: label,
            ceiling: 0.0,
            budget: 0.0,
            region: "",
            maximum: 0.0,
            attempts: 0,
            visitMinutes: 0,
            capacity: 0,
            status: CappedConsentFormRollupStatus.`open`
        )
    }
}
