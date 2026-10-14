import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a strict care protocol threshold is in its life cycle.
    enum StrictCareProtocolThresholdStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One strict care protocol threshold, with what the planners need to act on it.
    final class StrictCareProtocolThreshold {
        var code: String
        var name: String
        var createdAt: Int
        var version: Int
        var expiresAt: Int
        var segment: String
        var reviewer: String
        var archived: Bool
        var notes: String
        var description: String
        var status: StrictCareProtocolThresholdStatus

        init(code: String, name: String, createdAt: Int, version: Int, expiresAt: Int, segment: String, reviewer: String, archived: Bool, notes: String, description: String, status: StrictCareProtocolThresholdStatus) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.version = version
            self.expiresAt = expiresAt
            self.segment = segment
            self.reviewer = reviewer
            self.archived = archived
            self.notes = notes
            self.description = description
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

        func canMoveTo(_ next: StrictCareProtocolThresholdStatus) -> Bool {
            switch status {
            case .new:
                return next == StrictCareProtocolThresholdStatus.running
            case .queued:
                return next == StrictCareProtocolThresholdStatus.running || next == StrictCareProtocolThresholdStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == StrictCareProtocolThresholdStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictCareProtocolThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict care protocol threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedTotal() -> Double {
            return (Double(version) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> StrictCareProtocolThreshold {
            return StrictCareProtocolThreshold(
                code: code,
                name: name,
                createdAt: createdAt,
                version: version,
                expiresAt: expiresAt,
                segment: segment,
                reviewer: reviewer,
                archived: archived,
                notes: notes,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a strict care protocol threshold in status new.
    static func newStrictCareProtocolThreshold(_ code: String, name: String) -> StrictCareProtocolThreshold {
        return StrictCareProtocolThreshold(
            code: code,
            name: name,
            createdAt: 0,
            version: 0,
            expiresAt: 0,
            segment: "",
            reviewer: "",
            archived: false,
            notes: "",
            description: "",
            status: StrictCareProtocolThresholdStatus.new
        )
    }
}
