import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped panel budget is in its life cycle.
    enum CappedPanelBudgetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A capped panel budget. Its code is unique within a tenant.
    final class CappedPanelBudget {
        var code: String
        var title: String
        var limit: Int
        var tags: [String]
        var label: String
        var externalRef: String
        var reviewer: String
        var payer: String
        var facility: String
        var source: String
        var bed: String
        var status: CappedPanelBudgetStatus

        init(code: String, title: String, limit: Int, tags: [String], label: String, externalRef: String, reviewer: String, payer: String, facility: String, source: String, bed: String, status: CappedPanelBudgetStatus) {
            self.code = code
            self.title = title
            self.limit = limit
            self.tags = tags
            self.label = label
            self.externalRef = externalRef
            self.reviewer = reviewer
            self.payer = payer
            self.facility = facility
            self.source = source
            self.bed = bed
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

        func canMoveTo(_ next: CappedPanelBudgetStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == CappedPanelBudgetStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: CappedPanelBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped panel budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> CappedPanelBudget {
            return CappedPanelBudget(
                code: code,
                title: title,
                limit: limit,
                tags: tags,
                label: label,
                externalRef: externalRef,
                reviewer: reviewer,
                payer: payer,
                facility: facility,
                source: source,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a capped panel budget in status created.
    static func newCappedPanelBudget(_ code: String, title: String) -> CappedPanelBudget {
        return CappedPanelBudget(
            code: code,
            title: title,
            limit: 0,
            tags: [],
            label: "",
            externalRef: "",
            reviewer: "",
            payer: "",
            facility: "",
            source: "",
            bed: "",
            status: CappedPanelBudgetStatus.created
        )
    }
}
