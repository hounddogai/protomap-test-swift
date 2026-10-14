import AcmePlatform
import Foundation

extension Staffing {
    /// Where a legacy skill mix bundle is in its life cycle.
    enum LegacySkillMixBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a legacy skill mix bundle and its current status.
    final class LegacySkillMixBundle {
        var code: String
        var label: String
        var ceiling: Double
        var score: Double
        var batchSize: Int
        var priority: Int
        var allergy: String
        var ward: String
        var unit: String
        var status: LegacySkillMixBundleStatus

        init(code: String, label: String, ceiling: Double, score: Double, batchSize: Int, priority: Int, allergy: String, ward: String, unit: String, status: LegacySkillMixBundleStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.score = score
            self.batchSize = batchSize
            self.priority = priority
            self.allergy = allergy
            self.ward = ward
            self.unit = unit
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

        func canMoveTo(_ next: LegacySkillMixBundleStatus) -> Bool {
            switch status {
            case .idle:
                return next == LegacySkillMixBundleStatus.draining
            case .warming:
                return next == LegacySkillMixBundleStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == LegacySkillMixBundleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacySkillMixBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy skill mix bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netExposure() -> Double {
            return ((Double(batchSize) - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> LegacySkillMixBundle {
            return LegacySkillMixBundle(
                code: code,
                label: label,
                ceiling: ceiling,
                score: score,
                batchSize: batchSize,
                priority: priority,
                allergy: allergy,
                ward: ward,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a legacy skill mix bundle in status idle.
    static func newLegacySkillMixBundle(_ code: String, label: String) -> LegacySkillMixBundle {
        return LegacySkillMixBundle(
            code: code,
            label: label,
            ceiling: 0.0,
            score: 0.0,
            batchSize: 0,
            priority: 0,
            allergy: "",
            ward: "",
            unit: "",
            status: LegacySkillMixBundleStatus.idle
        )
    }
}
