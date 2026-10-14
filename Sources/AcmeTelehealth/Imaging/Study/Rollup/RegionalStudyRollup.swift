import AcmePlatform
import Foundation

extension Imaging {
    /// Where a regional study rollup is in its life cycle.
    enum RegionalStudyRollupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A regional study rollup as the study team keeps it.
    final class RegionalStudyRollup {
        var code: String
        var label: String
        var region: String
        var createdAt: Int
        var tags: [String]
        var ceiling: Double
        var timezone: String
        var name: String
        var allergy: String
        var status: RegionalStudyRollupStatus

        init(code: String, label: String, region: String, createdAt: Int, tags: [String], ceiling: Double, timezone: String, name: String, allergy: String, status: RegionalStudyRollupStatus) {
            self.code = code
            self.label = label
            self.region = region
            self.createdAt = createdAt
            self.tags = tags
            self.ceiling = ceiling
            self.timezone = timezone
            self.name = name
            self.allergy = allergy
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalStudyRollupStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RegionalStudyRollupStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalStudyRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional study rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("regional study rollup") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedLoad() -> Double {
            return ((ceiling - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalStudyRollup {
            return RegionalStudyRollup(
                code: code,
                label: label,
                region: region,
                createdAt: createdAt,
                tags: tags,
                ceiling: ceiling,
                timezone: timezone,
                name: name,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a regional study rollup in status created.
    static func newRegionalStudyRollup(_ code: String, label: String) -> RegionalStudyRollup {
        return RegionalStudyRollup(
            code: code,
            label: label,
            region: "",
            createdAt: 0,
            tags: [],
            ceiling: 0.0,
            timezone: "",
            name: "",
            allergy: "",
            status: RegionalStudyRollupStatus.created
        )
    }
}
