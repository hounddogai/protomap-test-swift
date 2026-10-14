import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy baseline is in its life cycle.
    enum ProxyBaselineStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One proxy baseline, with what the planners need to act on it.
    final class ProxyBaseline {
        var code: String
        var name: String
        var segment: String
        var externalRef: String
        var threshold: Double
        var graceDays: Int
        var tags: [String]
        var facility: String
        var notes: String
        var checksum: String
        var status: ProxyBaselineStatus

        init(code: String, name: String, segment: String, externalRef: String, threshold: Double, graceDays: Int, tags: [String], facility: String, notes: String, checksum: String, status: ProxyBaselineStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.externalRef = externalRef
            self.threshold = threshold
            self.graceDays = graceDays
            self.tags = tags
            self.facility = facility
            self.notes = notes
            self.checksum = checksum
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

        func canMoveTo(_ next: ProxyBaselineStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ProxyBaselineStatus.reopened || next == ProxyBaselineStatus.archived
            case .inReview:
                return next == ProxyBaselineStatus.archived
            case .resolved:
                switch next {
                case .reopened:
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

        func moveTo(_ next: ProxyBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("proxy baseline") \(code)"
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
            return (threshold * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> ProxyBaseline {
            return ProxyBaseline(
                code: code,
                name: name,
                segment: segment,
                externalRef: externalRef,
                threshold: threshold,
                graceDays: graceDays,
                tags: tags,
                facility: facility,
                notes: notes,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a proxy baseline in status open.
    static func newProxyBaseline(_ code: String, name: String) -> ProxyBaseline {
        return ProxyBaseline(
            code: code,
            name: name,
            segment: "",
            externalRef: "",
            threshold: 0.0,
            graceDays: 0,
            tags: [],
            facility: "",
            notes: "",
            checksum: "",
            status: ProxyBaselineStatus.`open`
        )
    }
}
