import AcmePlatform
import Foundation

extension Labs {
    /// Where a weighted accession rule is in its life cycle.
    enum WeightedAccessionRuleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a weighted accession rule and its current status.
    final class WeightedAccessionRule {
        var code: String
        var title: String
        var facility: String
        var ratio: Double
        var phone: String
        var status: WeightedAccessionRuleStatus

        init(code: String, title: String, facility: String, ratio: Double, phone: String, status: WeightedAccessionRuleStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.ratio = ratio
            self.phone = phone
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

        func canMoveTo(_ next: WeightedAccessionRuleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == WeightedAccessionRuleStatus.active || next == WeightedAccessionRuleStatus.closed
            case .active:
                return next == WeightedAccessionRuleStatus.closed
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

        func moveTo(_ next: WeightedAccessionRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted accession rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return ratio
        }

        func copyValue() -> WeightedAccessionRule {
            return WeightedAccessionRule(
                code: code,
                title: title,
                facility: facility,
                ratio: ratio,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a weighted accession rule in status draft.
    static func newWeightedAccessionRule(_ code: String, title: String) -> WeightedAccessionRule {
        return WeightedAccessionRule(
            code: code,
            title: title,
            facility: "",
            ratio: 0.0,
            phone: "",
            status: WeightedAccessionRuleStatus.draft
        )
    }
}
