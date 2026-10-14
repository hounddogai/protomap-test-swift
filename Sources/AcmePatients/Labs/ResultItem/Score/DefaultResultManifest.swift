import AcmePlatform
import Foundation

extension Labs {
    /// Where a default result manifest is in its life cycle.
    enum DefaultResultManifestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One default result manifest, with what the planners need to act on it.
    final class DefaultResultManifest {
        var code: String
        var label: String
        var summary: String
        var tags: [String]
        var endsAt: Int
        var minimum: Double
        var durationMinutes: Int
        var status: DefaultResultManifestStatus

        init(code: String, label: String, summary: String, tags: [String], endsAt: Int, minimum: Double, durationMinutes: Int, status: DefaultResultManifestStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.tags = tags
            self.endsAt = endsAt
            self.minimum = minimum
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultResultManifestStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == DefaultResultManifestStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: DefaultResultManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default result manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveValue() -> Double {
            return ((Double(durationMinutes) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> DefaultResultManifest {
            return DefaultResultManifest(
                code: code,
                label: label,
                summary: summary,
                tags: tags,
                endsAt: endsAt,
                minimum: minimum,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default result manifest in status planned.
    static func newDefaultResultManifest(_ code: String, label: String) -> DefaultResultManifest {
        return DefaultResultManifest(
            code: code,
            label: label,
            summary: "",
            tags: [],
            endsAt: 0,
            minimum: 0.0,
            durationMinutes: 0,
            status: DefaultResultManifestStatus.planned
        )
    }
}
