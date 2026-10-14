import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession budget is in its life cycle.
    enum AccessionBudgetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A accession budget. Its code is unique within a tenant.
    final class AccessionBudget {
        var code: String
        var label: String
        var updatedAt: Int
        var acuity: Int
        var title: String
        var tags: [String]
        var status: AccessionBudgetStatus

        init(code: String, label: String, updatedAt: Int, acuity: Int, title: String, tags: [String], status: AccessionBudgetStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.acuity = acuity
            self.title = title
            self.tags = tags
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

        func canMoveTo(_ next: AccessionBudgetStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == AccessionBudgetStatus.closed
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

        func moveTo(_ next: AccessionBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netValue() -> Double {
            return (Double(updatedAt) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> AccessionBudget {
            return AccessionBudget(
                code: code,
                label: label,
                updatedAt: updatedAt,
                acuity: acuity,
                title: title,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a accession budget in status draft.
    static func newAccessionBudget(_ code: String, label: String) -> AccessionBudget {
        return AccessionBudget(
            code: code,
            label: label,
            updatedAt: 0,
            acuity: 0,
            title: "",
            tags: [],
            status: AccessionBudgetStatus.draft
        )
    }
}
