import AcmePlatform
import Foundation

extension Labs {
    /// Where a weighted result rule is in its life cycle.
    enum WeightedResultRuleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A weighted result rule as the result team keeps it.
    final class WeightedResultRule {
        var code: String
        var name: String
        var batchSize: Int
        var rate: Double
        var startsAt: Int
        var ceiling: Double
        var acuity: Int
        var revision: Int
        var title: String
        var tags: [String]
        var status: WeightedResultRuleStatus

        init(code: String, name: String, batchSize: Int, rate: Double, startsAt: Int, ceiling: Double, acuity: Int, revision: Int, title: String, tags: [String], status: WeightedResultRuleStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.rate = rate
            self.startsAt = startsAt
            self.ceiling = ceiling
            self.acuity = acuity
            self.revision = revision
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

        func canMoveTo(_ next: WeightedResultRuleStatus) -> Bool {
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
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == WeightedResultRuleStatus.closed
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

        func moveTo(_ next: WeightedResultRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted result rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveLoad() -> Double {
            return (Double(batchSize) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> WeightedResultRule {
            return WeightedResultRule(
                code: code,
                name: name,
                batchSize: batchSize,
                rate: rate,
                startsAt: startsAt,
                ceiling: ceiling,
                acuity: acuity,
                revision: revision,
                title: title,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted result rule in status draft.
    static func newWeightedResultRule(_ code: String, name: String) -> WeightedResultRule {
        return WeightedResultRule(
            code: code,
            name: name,
            batchSize: 0,
            rate: 0.0,
            startsAt: 0,
            ceiling: 0.0,
            acuity: 0,
            revision: 0,
            title: "",
            tags: [],
            status: WeightedResultRuleStatus.draft
        )
    }
}
