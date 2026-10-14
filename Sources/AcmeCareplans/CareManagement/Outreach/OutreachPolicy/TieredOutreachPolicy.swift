import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered outreach policy is in its life cycle.
    enum TieredOutreachPolicyStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a tiered outreach policy and its current status.
    final class TieredOutreachPolicy {
        var code: String
        var name: String
        var category: String
        var country: String
        var label: String
        var threshold: Double
        var status: TieredOutreachPolicyStatus

        init(code: String, name: String, category: String, country: String, label: String, threshold: Double, status: TieredOutreachPolicyStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.country = country
            self.label = label
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredOutreachPolicyStatus) -> Bool {
            switch status {
            case .draft:
                return next == TieredOutreachPolicyStatus.active || next == TieredOutreachPolicyStatus.closed
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == TieredOutreachPolicyStatus.suspended || next == TieredOutreachPolicyStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: TieredOutreachPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered outreach policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return threshold
        }

        func copyValue() -> TieredOutreachPolicy {
            return TieredOutreachPolicy(
                code: code,
                name: name,
                category: category,
                country: country,
                label: label,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a tiered outreach policy in status draft.
    static func newTieredOutreachPolicy(_ code: String, name: String) -> TieredOutreachPolicy {
        return TieredOutreachPolicy(
            code: code,
            name: name,
            category: "",
            country: "",
            label: "",
            threshold: 0.0,
            status: TieredOutreachPolicyStatus.draft
        )
    }
}
