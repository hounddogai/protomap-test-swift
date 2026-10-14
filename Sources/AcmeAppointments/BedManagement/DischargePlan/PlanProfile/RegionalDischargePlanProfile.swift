import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a regional discharge plan profile is in its life cycle.
    enum RegionalDischargePlanProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A regional discharge plan profile as the discharge plan team keeps it.
    final class RegionalDischargePlanProfile {
        var code: String
        var title: String
        var ratio: Double
        var tags: [String]
        var region: String
        var status: RegionalDischargePlanProfileStatus

        init(code: String, title: String, ratio: Double, tags: [String], region: String, status: RegionalDischargePlanProfileStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.tags = tags
            self.region = region
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

        func canMoveTo(_ next: RegionalDischargePlanProfileStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == RegionalDischargePlanProfileStatus.closed
            case .active:
                return next == RegionalDischargePlanProfileStatus.suspended
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

        func moveTo(_ next: RegionalDischargePlanProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional discharge plan profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return ratio
        }

        func copyValue() -> RegionalDischargePlanProfile {
            return RegionalDischargePlanProfile(
                code: code,
                title: title,
                ratio: ratio,
                tags: tags,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a regional discharge plan profile in status draft.
    static func newRegionalDischargePlanProfile(_ code: String, title: String) -> RegionalDischargePlanProfile {
        return RegionalDischargePlanProfile(
            code: code,
            title: title,
            ratio: 0.0,
            tags: [],
            region: "",
            status: RegionalDischargePlanProfileStatus.draft
        )
    }
}
