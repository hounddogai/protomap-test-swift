import AcmePlatform
import Foundation

extension Consent {
    /// Where a manual witness rollup is in its life cycle.
    enum ManualWitnessRollupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A manual witness rollup as the witness team keeps it.
    final class ManualWitnessRollup {
        var code: String
        var name: String
        var startsAt: Int
        var windowDays: Int
        var version: Int
        var country: String
        var status: ManualWitnessRollupStatus

        init(code: String, name: String, startsAt: Int, windowDays: Int, version: Int, country: String, status: ManualWitnessRollupStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.windowDays = windowDays
            self.version = version
            self.country = country
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

        func canMoveTo(_ next: ManualWitnessRollupStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ManualWitnessRollupStatus.reopened
            case .resolved:
                switch next {
                case .archived:
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

        func moveTo(_ next: ManualWitnessRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual witness rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedTotal() -> Double {
            return ((Double(version) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> ManualWitnessRollup {
            return ManualWitnessRollup(
                code: code,
                name: name,
                startsAt: startsAt,
                windowDays: windowDays,
                version: version,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a manual witness rollup in status open.
    static func newManualWitnessRollup(_ code: String, name: String) -> ManualWitnessRollup {
        return ManualWitnessRollup(
            code: code,
            name: name,
            startsAt: 0,
            windowDays: 0,
            version: 0,
            country: "",
            status: ManualWitnessRollupStatus.`open`
        )
    }
}
