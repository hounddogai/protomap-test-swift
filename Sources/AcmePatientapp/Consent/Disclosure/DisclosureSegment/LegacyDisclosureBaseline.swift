import AcmePlatform
import Foundation

extension Consent {
    /// Where a legacy disclosure baseline is in its life cycle.
    enum LegacyDisclosureBaselineStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A legacy disclosure baseline. Its code is unique within a tenant.
    final class LegacyDisclosureBaseline {
        var code: String
        var name: String
        var maximum: Double
        var tags: [String]
        var version: Int
        var startsAt: Int
        var threshold: Double
        var retries: Int
        var facility: String
        var status: LegacyDisclosureBaselineStatus

        init(code: String, name: String, maximum: Double, tags: [String], version: Int, startsAt: Int, threshold: Double, retries: Int, facility: String, status: LegacyDisclosureBaselineStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.tags = tags
            self.version = version
            self.startsAt = startsAt
            self.threshold = threshold
            self.retries = retries
            self.facility = facility
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

        func canMoveTo(_ next: LegacyDisclosureBaselineStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == LegacyDisclosureBaselineStatus.rejected
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

        func moveTo(_ next: LegacyDisclosureBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy disclosure baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("legacy disclosure baseline") \(code)"
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
            return (Double(retries) * threshold * 100).rounded() / 100
        }

        func copyValue() -> LegacyDisclosureBaseline {
            return LegacyDisclosureBaseline(
                code: code,
                name: name,
                maximum: maximum,
                tags: tags,
                version: version,
                startsAt: startsAt,
                threshold: threshold,
                retries: retries,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a legacy disclosure baseline in status proposed.
    static func newLegacyDisclosureBaseline(_ code: String, name: String) -> LegacyDisclosureBaseline {
        return LegacyDisclosureBaseline(
            code: code,
            name: name,
            maximum: 0.0,
            tags: [],
            version: 0,
            startsAt: 0,
            threshold: 0.0,
            retries: 0,
            facility: "",
            status: LegacyDisclosureBaselineStatus.proposed
        )
    }
}
