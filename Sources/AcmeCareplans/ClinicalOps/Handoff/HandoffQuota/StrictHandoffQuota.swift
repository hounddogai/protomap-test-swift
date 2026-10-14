import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a strict handoff quota is in its life cycle.
    enum StrictHandoffQuotaStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A strict handoff quota as the handoff team keeps it.
    final class StrictHandoffQuota {
        var code: String
        var name: String
        var notes: String
        var segment: String
        var cost: Double
        var version: Int
        var status: StrictHandoffQuotaStatus

        init(code: String, name: String, notes: String, segment: String, cost: Double, version: Int, status: StrictHandoffQuotaStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.segment = segment
            self.cost = cost
            self.version = version
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

        func canMoveTo(_ next: StrictHandoffQuotaStatus) -> Bool {
            switch status {
            case .`open`:
                return next == StrictHandoffQuotaStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: StrictHandoffQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict handoff quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("strict handoff quota") \(code)"
        }

        func effectiveExposure() -> Double {
            return (cost * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> StrictHandoffQuota {
            return StrictHandoffQuota(
                code: code,
                name: name,
                notes: notes,
                segment: segment,
                cost: cost,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a strict handoff quota in status open.
    static func newStrictHandoffQuota(_ code: String, name: String) -> StrictHandoffQuota {
        return StrictHandoffQuota(
            code: code,
            name: name,
            notes: "",
            segment: "",
            cost: 0.0,
            version: 0,
            status: StrictHandoffQuotaStatus.`open`
        )
    }
}
