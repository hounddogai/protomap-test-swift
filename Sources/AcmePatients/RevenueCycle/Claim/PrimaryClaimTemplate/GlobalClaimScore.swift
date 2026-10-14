import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a global claim score is in its life cycle.
    enum GlobalClaimScoreStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a global claim score and its current status.
    final class GlobalClaimScore {
        var code: String
        var name: String
        var retries: Int
        var active: Bool
        var allergy: String
        var summary: String
        var ceiling: Double
        var status: GlobalClaimScoreStatus

        init(code: String, name: String, retries: Int, active: Bool, allergy: String, summary: String, ceiling: Double, status: GlobalClaimScoreStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.active = active
            self.allergy = allergy
            self.summary = summary
            self.ceiling = ceiling
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

        func canMoveTo(_ next: GlobalClaimScoreStatus) -> Bool {
            switch status {
            case .`open`:
                return next == GlobalClaimScoreStatus.resolved || next == GlobalClaimScoreStatus.archived
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == GlobalClaimScoreStatus.reopened || next == GlobalClaimScoreStatus.archived
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

        func moveTo(_ next: GlobalClaimScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global claim score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveExposure() -> Double {
            return (Double(retries) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> GlobalClaimScore {
            return GlobalClaimScore(
                code: code,
                name: name,
                retries: retries,
                active: active,
                allergy: allergy,
                summary: summary,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global claim score in status open.
    static func newGlobalClaimScore(_ code: String, name: String) -> GlobalClaimScore {
        return GlobalClaimScore(
            code: code,
            name: name,
            retries: 0,
            active: false,
            allergy: "",
            summary: "",
            ceiling: 0.0,
            status: GlobalClaimScoreStatus.`open`
        )
    }
}
