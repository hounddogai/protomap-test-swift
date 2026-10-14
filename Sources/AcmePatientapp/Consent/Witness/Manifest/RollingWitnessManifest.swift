import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling witness manifest is in its life cycle.
    enum RollingWitnessManifestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One rolling witness manifest, with what the planners need to act on it.
    final class RollingWitnessManifest {
        var code: String
        var title: String
        var visible: Bool
        var category: String
        var name: String
        var margin: Double
        var maximum: Double
        var tags: [String]
        var source: String
        var retries: Int
        var region: String
        var status: RollingWitnessManifestStatus

        init(code: String, title: String, visible: Bool, category: String, name: String, margin: Double, maximum: Double, tags: [String], source: String, retries: Int, region: String, status: RollingWitnessManifestStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.category = category
            self.name = name
            self.margin = margin
            self.maximum = maximum
            self.tags = tags
            self.source = source
            self.retries = retries
            self.region = region
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

        func canMoveTo(_ next: RollingWitnessManifestStatus) -> Bool {
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
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == RollingWitnessManifestStatus.archived
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

        func moveTo(_ next: RollingWitnessManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling witness manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedLoad() -> Double {
            return ((maximum + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> RollingWitnessManifest {
            return RollingWitnessManifest(
                code: code,
                title: title,
                visible: visible,
                category: category,
                name: name,
                margin: margin,
                maximum: maximum,
                tags: tags,
                source: source,
                retries: retries,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a rolling witness manifest in status open.
    static func newRollingWitnessManifest(_ code: String, title: String) -> RollingWitnessManifest {
        return RollingWitnessManifest(
            code: code,
            title: title,
            visible: false,
            category: "",
            name: "",
            margin: 0.0,
            maximum: 0.0,
            tags: [],
            source: "",
            retries: 0,
            region: "",
            status: RollingWitnessManifestStatus.`open`
        )
    }
}
