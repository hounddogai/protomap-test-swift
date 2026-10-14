import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a strict remittance estimate is in its life cycle.
    enum StrictRemittanceEstimateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A strict remittance estimate as the remittance team keeps it.
    final class StrictRemittanceEstimate {
        var code: String
        var name: String
        var tags: [String]
        var source: String
        var rate: Double
        var maximum: Double
        var status: StrictRemittanceEstimateStatus

        init(code: String, name: String, tags: [String], source: String, rate: Double, maximum: Double, status: StrictRemittanceEstimateStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.source = source
            self.rate = rate
            self.maximum = maximum
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

        func canMoveTo(_ next: StrictRemittanceEstimateStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
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
                return next == StrictRemittanceEstimateStatus.suspended || next == StrictRemittanceEstimateStatus.closed
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

        func moveTo(_ next: StrictRemittanceEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict remittance estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedValue() -> Double {
            return ((maximum - rate) * 100).rounded() / 100
        }

        func copyValue() -> StrictRemittanceEstimate {
            return StrictRemittanceEstimate(
                code: code,
                name: name,
                tags: tags,
                source: source,
                rate: rate,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a strict remittance estimate in status draft.
    static func newStrictRemittanceEstimate(_ code: String, name: String) -> StrictRemittanceEstimate {
        return StrictRemittanceEstimate(
            code: code,
            name: name,
            tags: [],
            source: "",
            rate: 0.0,
            maximum: 0.0,
            status: StrictRemittanceEstimateStatus.draft
        )
    }
}
