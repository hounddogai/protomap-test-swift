import AcmePlatform
import Foundation

extension Staffing {
    /// Where a seasonal skill mix segment is in its life cycle.
    enum SeasonalSkillMixSegmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a seasonal skill mix segment and its current status.
    final class SeasonalSkillMixSegment {
        var code: String
        var name: String
        var category: String
        var allergy: String
        var ratio: Double
        var checksum: String
        var durationMinutes: Int
        var maximum: Double
        var status: SeasonalSkillMixSegmentStatus

        init(code: String, name: String, category: String, allergy: String, ratio: Double, checksum: String, durationMinutes: Int, maximum: Double, status: SeasonalSkillMixSegmentStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.allergy = allergy
            self.ratio = ratio
            self.checksum = checksum
            self.durationMinutes = durationMinutes
            self.maximum = maximum
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

        func canMoveTo(_ next: SeasonalSkillMixSegmentStatus) -> Bool {
            switch status {
            case .idle:
                return next == SeasonalSkillMixSegmentStatus.ready
            case .warming:
                return next == SeasonalSkillMixSegmentStatus.draining || next == SeasonalSkillMixSegmentStatus.stopped
            case .ready:
                return next == SeasonalSkillMixSegmentStatus.stopped
            case .draining:
                return next == SeasonalSkillMixSegmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalSkillMixSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal skill mix segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal skill mix segment") \(code)"
        }

        func weightedValue() -> Double {
            return (Double(durationMinutes) * ratio * 100).rounded() / 100
        }

        func copyValue() -> SeasonalSkillMixSegment {
            return SeasonalSkillMixSegment(
                code: code,
                name: name,
                category: category,
                allergy: allergy,
                ratio: ratio,
                checksum: checksum,
                durationMinutes: durationMinutes,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a seasonal skill mix segment in status idle.
    static func newSeasonalSkillMixSegment(_ code: String, name: String) -> SeasonalSkillMixSegment {
        return SeasonalSkillMixSegment(
            code: code,
            name: name,
            category: "",
            allergy: "",
            ratio: 0.0,
            checksum: "",
            durationMinutes: 0,
            maximum: 0.0,
            status: SeasonalSkillMixSegmentStatus.idle
        )
    }
}
