import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement bundle is in its life cycle.
    enum StatementBundleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One statement bundle, with what the planners need to act on it.
    final class StatementBundle {
        var code: String
        var name: String
        var segment: String
        var timezone: String
        var externalRef: String
        var margin: Double
        var capacity: Int
        var limit: Int
        var status: StatementBundleStatus

        init(code: String, name: String, segment: String, timezone: String, externalRef: String, margin: Double, capacity: Int, limit: Int, status: StatementBundleStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.timezone = timezone
            self.externalRef = externalRef
            self.margin = margin
            self.capacity = capacity
            self.limit = limit
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

        func canMoveTo(_ next: StatementBundleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == StatementBundleStatus.resolved || next == StatementBundleStatus.archived
            case .inReview:
                return next == StatementBundleStatus.reopened || next == StatementBundleStatus.archived
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

        func moveTo(_ next: StatementBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveVolume() -> Double {
            return ((Double(limit) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> StatementBundle {
            return StatementBundle(
                code: code,
                name: name,
                segment: segment,
                timezone: timezone,
                externalRef: externalRef,
                margin: margin,
                capacity: capacity,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a statement bundle in status open.
    static func newStatementBundle(_ code: String, name: String) -> StatementBundle {
        return StatementBundle(
            code: code,
            name: name,
            segment: "",
            timezone: "",
            externalRef: "",
            margin: 0.0,
            capacity: 0,
            limit: 0,
            status: StatementBundleStatus.`open`
        )
    }
}
