import AcmePlatform
import Foundation

extension Consent {
    /// Where a pending language digest is in its life cycle.
    enum PendingLanguageDigestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A pending language digest. Its code is unique within a tenant.
    final class PendingLanguageDigest {
        var code: String
        var name: String
        var payer: String
        var bed: String
        var graceDays: Int
        var cost: Double
        var ceiling: Double
        var reviewer: String
        var priority: Int
        var status: PendingLanguageDigestStatus

        init(code: String, name: String, payer: String, bed: String, graceDays: Int, cost: Double, ceiling: Double, reviewer: String, priority: Int, status: PendingLanguageDigestStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.bed = bed
            self.graceDays = graceDays
            self.cost = cost
            self.ceiling = ceiling
            self.reviewer = reviewer
            self.priority = priority
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

        func canMoveTo(_ next: PendingLanguageDigestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == PendingLanguageDigestStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: PendingLanguageDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending language digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netLoad() -> Double {
            return (cost * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> PendingLanguageDigest {
            return PendingLanguageDigest(
                code: code,
                name: name,
                payer: payer,
                bed: bed,
                graceDays: graceDays,
                cost: cost,
                ceiling: ceiling,
                reviewer: reviewer,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending language digest in status idle.
    static func newPendingLanguageDigest(_ code: String, name: String) -> PendingLanguageDigest {
        return PendingLanguageDigest(
            code: code,
            name: name,
            payer: "",
            bed: "",
            graceDays: 0,
            cost: 0.0,
            ceiling: 0.0,
            reviewer: "",
            priority: 0,
            status: PendingLanguageDigestStatus.idle
        )
    }
}
