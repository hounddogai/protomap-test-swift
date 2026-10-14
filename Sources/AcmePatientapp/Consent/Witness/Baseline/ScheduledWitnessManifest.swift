import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled witness manifest is in its life cycle.
    enum ScheduledWitnessManifestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A scheduled witness manifest as the witness team keeps it.
    final class ScheduledWitnessManifest {
        var code: String
        var name: String
        var source: String
        var tags: [String]
        var archived: Bool
        var revision: Int
        var visitMinutes: Int
        var status: ScheduledWitnessManifestStatus

        init(code: String, name: String, source: String, tags: [String], archived: Bool, revision: Int, visitMinutes: Int, status: ScheduledWitnessManifestStatus) {
            self.code = code
            self.name = name
            self.source = source
            self.tags = tags
            self.archived = archived
            self.revision = revision
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledWitnessManifestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ScheduledWitnessManifestStatus.running || next == ScheduledWitnessManifestStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ScheduledWitnessManifestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledWitnessManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled witness manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("scheduled witness manifest") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netVolume() -> Double {
            return ((Double(revision) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledWitnessManifest {
            return ScheduledWitnessManifest(
                code: code,
                name: name,
                source: source,
                tags: tags,
                archived: archived,
                revision: revision,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a scheduled witness manifest in status new.
    static func newScheduledWitnessManifest(_ code: String, name: String) -> ScheduledWitnessManifest {
        return ScheduledWitnessManifest(
            code: code,
            name: name,
            source: "",
            tags: [],
            archived: false,
            revision: 0,
            visitMinutes: 0,
            status: ScheduledWitnessManifestStatus.new
        )
    }
}
