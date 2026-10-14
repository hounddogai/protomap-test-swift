import AcmePlatform
import Foundation

extension Consent {
    /// Where a primary language batch is in its life cycle.
    enum PrimaryLanguageBatchStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A primary language batch as the language team keeps it.
    final class PrimaryLanguageBatch {
        var code: String
        var name: String
        var category: String
        var label: String
        var margin: Double
        var source: String
        var rate: Double
        var cost: Double
        var ceiling: Double
        var status: PrimaryLanguageBatchStatus

        init(code: String, name: String, category: String, label: String, margin: Double, source: String, rate: Double, cost: Double, ceiling: Double, status: PrimaryLanguageBatchStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.label = label
            self.margin = margin
            self.source = source
            self.rate = rate
            self.cost = cost
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryLanguageBatchStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == PrimaryLanguageBatchStatus.draining || next == PrimaryLanguageBatchStatus.stopped
            case .draining:
                return next == PrimaryLanguageBatchStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryLanguageBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary language batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func projectedValue() -> Double {
            return (margin * ceiling * 100).rounded() / 100
        }

        func copyValue() -> PrimaryLanguageBatch {
            return PrimaryLanguageBatch(
                code: code,
                name: name,
                category: category,
                label: label,
                margin: margin,
                source: source,
                rate: rate,
                cost: cost,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a primary language batch in status idle.
    static func newPrimaryLanguageBatch(_ code: String, name: String) -> PrimaryLanguageBatch {
        return PrimaryLanguageBatch(
            code: code,
            name: name,
            category: "",
            label: "",
            margin: 0.0,
            source: "",
            rate: 0.0,
            cost: 0.0,
            ceiling: 0.0,
            status: PrimaryLanguageBatchStatus.idle
        )
    }
}
