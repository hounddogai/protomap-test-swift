import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched language threshold is in its life cycle.
    enum BatchedLanguageThresholdStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A batched language threshold as the language team keeps it.
    final class BatchedLanguageThreshold {
        var code: String
        var label: String
        var version: Int
        var tags: [String]
        var updatedAt: Int
        var weight: Double
        var description: String
        var visitMinutes: Int
        var pinned: Bool
        var ownerID: String
        var status: BatchedLanguageThresholdStatus

        init(code: String, label: String, version: Int, tags: [String], updatedAt: Int, weight: Double, description: String, visitMinutes: Int, pinned: Bool, ownerID: String, status: BatchedLanguageThresholdStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.tags = tags
            self.updatedAt = updatedAt
            self.weight = weight
            self.description = description
            self.visitMinutes = visitMinutes
            self.pinned = pinned
            self.ownerID = ownerID
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

        func canMoveTo(_ next: BatchedLanguageThresholdStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == BatchedLanguageThresholdStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedLanguageThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched language threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
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

        func effectiveTotal() -> Double {
            return ((Double(visitMinutes) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedLanguageThreshold {
            return BatchedLanguageThreshold(
                code: code,
                label: label,
                version: version,
                tags: tags,
                updatedAt: updatedAt,
                weight: weight,
                description: description,
                visitMinutes: visitMinutes,
                pinned: pinned,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched language threshold in status planned.
    static func newBatchedLanguageThreshold(_ code: String, label: String) -> BatchedLanguageThreshold {
        return BatchedLanguageThreshold(
            code: code,
            label: label,
            version: 0,
            tags: [],
            updatedAt: 0,
            weight: 0.0,
            description: "",
            visitMinutes: 0,
            pinned: false,
            ownerID: "",
            status: BatchedLanguageThresholdStatus.planned
        )
    }
}
