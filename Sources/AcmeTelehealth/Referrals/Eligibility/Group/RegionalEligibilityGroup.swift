import AcmePlatform
import Foundation

extension Referrals {
    /// Where a regional eligibility group is in its life cycle.
    enum RegionalEligibilityGroupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A regional eligibility group. Its code is unique within a tenant.
    final class RegionalEligibilityGroup {
        var code: String
        var label: String
        var score: Double
        var category: String
        var clinicianID: String
        var title: String
        var status: RegionalEligibilityGroupStatus

        init(code: String, label: String, score: Double, category: String, clinicianID: String, title: String, status: RegionalEligibilityGroupStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.category = category
            self.clinicianID = clinicianID
            self.title = title
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

        func canMoveTo(_ next: RegionalEligibilityGroupStatus) -> Bool {
            switch status {
            case .draft:
                return next == RegionalEligibilityGroupStatus.pending
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RegionalEligibilityGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional eligibility group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> RegionalEligibilityGroup {
            return RegionalEligibilityGroup(
                code: code,
                label: label,
                score: score,
                category: category,
                clinicianID: clinicianID,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a regional eligibility group in status draft.
    static func newRegionalEligibilityGroup(_ code: String, label: String) -> RegionalEligibilityGroup {
        return RegionalEligibilityGroup(
            code: code,
            label: label,
            score: 0.0,
            category: "",
            clinicianID: "",
            title: "",
            status: RegionalEligibilityGroupStatus.draft
        )
    }
}
