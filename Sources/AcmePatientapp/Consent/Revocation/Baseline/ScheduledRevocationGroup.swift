import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled revocation group is in its life cycle.
    enum ScheduledRevocationGroupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A scheduled revocation group as the revocation team keeps it.
    final class ScheduledRevocationGroup {
        var code: String
        var name: String
        var batchSize: Int
        var unit: String
        var startsAt: Int
        var priority: Int
        var status: ScheduledRevocationGroupStatus

        init(code: String, name: String, batchSize: Int, unit: String, startsAt: Int, priority: Int, status: ScheduledRevocationGroupStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.unit = unit
            self.startsAt = startsAt
            self.priority = priority
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

        func canMoveTo(_ next: ScheduledRevocationGroupStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
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

        func moveTo(_ next: ScheduledRevocationGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled revocation group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedLoad() -> Double {
            return ((Double(batchSize) - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledRevocationGroup {
            return ScheduledRevocationGroup(
                code: code,
                name: name,
                batchSize: batchSize,
                unit: unit,
                startsAt: startsAt,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a scheduled revocation group in status open.
    static func newScheduledRevocationGroup(_ code: String, name: String) -> ScheduledRevocationGroup {
        return ScheduledRevocationGroup(
            code: code,
            name: name,
            batchSize: 0,
            unit: "",
            startsAt: 0,
            priority: 0,
            status: ScheduledRevocationGroupStatus.`open`
        )
    }
}
