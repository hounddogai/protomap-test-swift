import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix entry is in its life cycle.
    enum SkillMixEntryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a skill mix entry and its current status.
    final class SkillMixEntry {
        var code: String
        var title: String
        var region: String
        var visitMinutes: Int
        var allergy: String
        var maximum: Double
        var diagnosisCode: String
        var budget: Double
        var contactEmail: String
        var capacity: Int
        var unit: String
        var status: SkillMixEntryStatus

        init(code: String, title: String, region: String, visitMinutes: Int, allergy: String, maximum: Double, diagnosisCode: String, budget: Double, contactEmail: String, capacity: Int, unit: String, status: SkillMixEntryStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.visitMinutes = visitMinutes
            self.allergy = allergy
            self.maximum = maximum
            self.diagnosisCode = diagnosisCode
            self.budget = budget
            self.contactEmail = contactEmail
            self.capacity = capacity
            self.unit = unit
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

        func canMoveTo(_ next: SkillMixEntryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == SkillMixEntryStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == SkillMixEntryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("skill mix entry") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((Double(visitMinutes) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixEntry {
            return SkillMixEntry(
                code: code,
                title: title,
                region: region,
                visitMinutes: visitMinutes,
                allergy: allergy,
                maximum: maximum,
                diagnosisCode: diagnosisCode,
                budget: budget,
                contactEmail: contactEmail,
                capacity: capacity,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a skill mix entry in status new.
    static func newSkillMixEntry(_ code: String, title: String) -> SkillMixEntry {
        return SkillMixEntry(
            code: code,
            title: title,
            region: "",
            visitMinutes: 0,
            allergy: "",
            maximum: 0.0,
            diagnosisCode: "",
            budget: 0.0,
            contactEmail: "",
            capacity: 0,
            unit: "",
            status: SkillMixEntryStatus.new
        )
    }
}
