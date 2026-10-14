import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a legacy risk score override is in its life cycle.
    enum LegacyRiskScoreOverrideStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One legacy risk score override, with what the planners need to act on it.
    final class LegacyRiskScoreOverride {
        var code: String
        var name: String
        var priority: Int
        var specialty: String
        var visitMinutes: Int
        var tags: [String]
        var durationMinutes: Int
        var bed: String
        var batchSize: Int
        var channel: String
        var category: String
        var status: LegacyRiskScoreOverrideStatus

        init(code: String, name: String, priority: Int, specialty: String, visitMinutes: Int, tags: [String], durationMinutes: Int, bed: String, batchSize: Int, channel: String, category: String, status: LegacyRiskScoreOverrideStatus) {
            self.code = code
            self.name = name
            self.priority = priority
            self.specialty = specialty
            self.visitMinutes = visitMinutes
            self.tags = tags
            self.durationMinutes = durationMinutes
            self.bed = bed
            self.batchSize = batchSize
            self.channel = channel
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyRiskScoreOverrideStatus) -> Bool {
            switch status {
            case .idle:
                return next == LegacyRiskScoreOverrideStatus.draining || next == LegacyRiskScoreOverrideStatus.stopped
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == LegacyRiskScoreOverrideStatus.draining
            case .draining:
                return next == LegacyRiskScoreOverrideStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyRiskScoreOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy risk score override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveVolume() -> Double {
            return ((Double(priority) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyRiskScoreOverride {
            return LegacyRiskScoreOverride(
                code: code,
                name: name,
                priority: priority,
                specialty: specialty,
                visitMinutes: visitMinutes,
                tags: tags,
                durationMinutes: durationMinutes,
                bed: bed,
                batchSize: batchSize,
                channel: channel,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a legacy risk score override in status idle.
    static func newLegacyRiskScoreOverride(_ code: String, name: String) -> LegacyRiskScoreOverride {
        return LegacyRiskScoreOverride(
            code: code,
            name: name,
            priority: 0,
            specialty: "",
            visitMinutes: 0,
            tags: [],
            durationMinutes: 0,
            bed: "",
            batchSize: 0,
            channel: "",
            category: "",
            status: LegacyRiskScoreOverrideStatus.idle
        )
    }
}
