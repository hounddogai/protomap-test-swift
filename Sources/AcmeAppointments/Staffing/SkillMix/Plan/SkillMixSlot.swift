import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix slot is in its life cycle.
    enum SkillMixSlotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A skill mix slot. Its code is unique within a tenant.
    final class SkillMixSlot {
        var code: String
        var title: String
        var label: String
        var allergy: String
        var name: String
        var endsAt: Int
        var rate: Double
        var visitMinutes: Int
        var bed: String
        var minimum: Double
        var status: SkillMixSlotStatus

        init(code: String, title: String, label: String, allergy: String, name: String, endsAt: Int, rate: Double, visitMinutes: Int, bed: String, minimum: Double, status: SkillMixSlotStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.allergy = allergy
            self.name = name
            self.endsAt = endsAt
            self.rate = rate
            self.visitMinutes = visitMinutes
            self.bed = bed
            self.minimum = minimum
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

        func canMoveTo(_ next: SkillMixSlotStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == SkillMixSlotStatus.ready || next == SkillMixSlotStatus.stopped
            case .ready:
                return next == SkillMixSlotStatus.draining || next == SkillMixSlotStatus.stopped
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

        func moveTo(_ next: SkillMixSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func netVolume() -> Double {
            return ((Double(visitMinutes) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixSlot {
            return SkillMixSlot(
                code: code,
                title: title,
                label: label,
                allergy: allergy,
                name: name,
                endsAt: endsAt,
                rate: rate,
                visitMinutes: visitMinutes,
                bed: bed,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a skill mix slot in status idle.
    static func newSkillMixSlot(_ code: String, title: String) -> SkillMixSlot {
        return SkillMixSlot(
            code: code,
            title: title,
            label: "",
            allergy: "",
            name: "",
            endsAt: 0,
            rate: 0.0,
            visitMinutes: 0,
            bed: "",
            minimum: 0.0,
            status: SkillMixSlotStatus.idle
        )
    }
}
