import AcmePlatform
import Foundation

extension Consent {
    /// Where a primary proxy summary is in its life cycle.
    enum PrimaryProxySummaryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One primary proxy summary, with what the planners need to act on it.
    final class PrimaryProxySummary {
        var code: String
        var name: String
        var reviewer: String
        var clinicianID: String
        var tags: [String]
        var bed: String
        var attributes: [String: String]
        var windowDays: Int
        var status: PrimaryProxySummaryStatus

        init(code: String, name: String, reviewer: String, clinicianID: String, tags: [String], bed: String, attributes: [String: String], windowDays: Int, status: PrimaryProxySummaryStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.clinicianID = clinicianID
            self.tags = tags
            self.bed = bed
            self.attributes = attributes
            self.windowDays = windowDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryProxySummaryStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == PrimaryProxySummaryStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: PrimaryProxySummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary proxy summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return Double(windowDays)
        }

        func copyValue() -> PrimaryProxySummary {
            return PrimaryProxySummary(
                code: code,
                name: name,
                reviewer: reviewer,
                clinicianID: clinicianID,
                tags: tags,
                bed: bed,
                attributes: attributes,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary proxy summary in status proposed.
    static func newPrimaryProxySummary(_ code: String, name: String) -> PrimaryProxySummary {
        return PrimaryProxySummary(
            code: code,
            name: name,
            reviewer: "",
            clinicianID: "",
            tags: [],
            bed: "",
            attributes: [:],
            windowDays: 0,
            status: PrimaryProxySummaryStatus.proposed
        )
    }
}
