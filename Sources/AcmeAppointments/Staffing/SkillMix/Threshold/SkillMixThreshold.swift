import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix threshold is in its life cycle.
    enum SkillMixThresholdStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One skill mix threshold, with what the planners need to act on it.
    final class SkillMixThreshold {
        var code: String
        var title: String
        var encounterID: String
        var acuity: Int
        var summary: String
        var region: String
        var channel: String
        var budget: Double
        var bed: String
        var notes: String
        var specialty: String
        var status: SkillMixThresholdStatus

        init(code: String, title: String, encounterID: String, acuity: Int, summary: String, region: String, channel: String, budget: Double, bed: String, notes: String, specialty: String, status: SkillMixThresholdStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.acuity = acuity
            self.summary = summary
            self.region = region
            self.channel = channel
            self.budget = budget
            self.bed = bed
            self.notes = notes
            self.specialty = specialty
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

        func canMoveTo(_ next: SkillMixThresholdStatus) -> Bool {
            switch status {
            case .new:
                return next == SkillMixThresholdStatus.running || next == SkillMixThresholdStatus.failed
            case .queued:
                return next == SkillMixThresholdStatus.done
            case .running:
                return next == SkillMixThresholdStatus.done || next == SkillMixThresholdStatus.failed
            case .done:
                return next == SkillMixThresholdStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netValue() -> Double {
            return ((Double(acuity) + budget) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixThreshold {
            return SkillMixThreshold(
                code: code,
                title: title,
                encounterID: encounterID,
                acuity: acuity,
                summary: summary,
                region: region,
                channel: channel,
                budget: budget,
                bed: bed,
                notes: notes,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a skill mix threshold in status new.
    static func newSkillMixThreshold(_ code: String, title: String) -> SkillMixThreshold {
        return SkillMixThreshold(
            code: code,
            title: title,
            encounterID: "",
            acuity: 0,
            summary: "",
            region: "",
            channel: "",
            budget: 0.0,
            bed: "",
            notes: "",
            specialty: "",
            status: SkillMixThresholdStatus.new
        )
    }
}
