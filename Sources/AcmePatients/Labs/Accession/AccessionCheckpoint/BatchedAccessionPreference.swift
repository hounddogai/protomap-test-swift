import AcmePlatform
import Foundation

extension Labs {
    /// Where a batched accession preference is in its life cycle.
    enum BatchedAccessionPreferenceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a batched accession preference and its current status.
    final class BatchedAccessionPreference {
        var code: String
        var label: String
        var name: String
        var bed: String
        var tags: [String]
        var ceiling: Double
        var ownerID: String
        var notes: String
        var retries: Int
        var startsAt: Int
        var status: BatchedAccessionPreferenceStatus

        init(code: String, label: String, name: String, bed: String, tags: [String], ceiling: Double, ownerID: String, notes: String, retries: Int, startsAt: Int, status: BatchedAccessionPreferenceStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.bed = bed
            self.tags = tags
            self.ceiling = ceiling
            self.ownerID = ownerID
            self.notes = notes
            self.retries = retries
            self.startsAt = startsAt
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

        func canMoveTo(_ next: BatchedAccessionPreferenceStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == BatchedAccessionPreferenceStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedAccessionPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched accession preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedExposure() -> Double {
            return ((Double(retries) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedAccessionPreference {
            return BatchedAccessionPreference(
                code: code,
                label: label,
                name: name,
                bed: bed,
                tags: tags,
                ceiling: ceiling,
                ownerID: ownerID,
                notes: notes,
                retries: retries,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched accession preference in status new.
    static func newBatchedAccessionPreference(_ code: String, label: String) -> BatchedAccessionPreference {
        return BatchedAccessionPreference(
            code: code,
            label: label,
            name: "",
            bed: "",
            tags: [],
            ceiling: 0.0,
            ownerID: "",
            notes: "",
            retries: 0,
            startsAt: 0,
            status: BatchedAccessionPreferenceStatus.new
        )
    }
}
