import AcmePlatform
import Foundation

extension Staffing {
    /// Where a capped skill mix cycle is in its life cycle.
    enum CappedSkillMixCycleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A capped skill mix cycle as the skill mix team keeps it.
    final class CappedSkillMixCycle {
        var code: String
        var title: String
        var attempts: Int
        var patientRef: String
        var attributes: [String: String]
        var limit: Int
        var acuity: Int
        var unit: String
        var allergy: String
        var status: CappedSkillMixCycleStatus

        init(code: String, title: String, attempts: Int, patientRef: String, attributes: [String: String], limit: Int, acuity: Int, unit: String, allergy: String, status: CappedSkillMixCycleStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.patientRef = patientRef
            self.attributes = attributes
            self.limit = limit
            self.acuity = acuity
            self.unit = unit
            self.allergy = allergy
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

        func canMoveTo(_ next: CappedSkillMixCycleStatus) -> Bool {
            switch status {
            case .idle:
                return next == CappedSkillMixCycleStatus.ready
            case .warming:
                return next == CappedSkillMixCycleStatus.draining
            case .ready:
                return next == CappedSkillMixCycleStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: CappedSkillMixCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped skill mix cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped skill mix cycle") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedTotal() -> Double {
            return (Double(limit) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> CappedSkillMixCycle {
            return CappedSkillMixCycle(
                code: code,
                title: title,
                attempts: attempts,
                patientRef: patientRef,
                attributes: attributes,
                limit: limit,
                acuity: acuity,
                unit: unit,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a capped skill mix cycle in status idle.
    static func newCappedSkillMixCycle(_ code: String, title: String) -> CappedSkillMixCycle {
        return CappedSkillMixCycle(
            code: code,
            title: title,
            attempts: 0,
            patientRef: "",
            attributes: [:],
            limit: 0,
            acuity: 0,
            unit: "",
            allergy: "",
            status: CappedSkillMixCycleStatus.idle
        )
    }
}
