import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix variance is in its life cycle.
    enum SkillMixVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A skill mix variance as the skill mix team keeps it.
    final class SkillMixVariance {
        var code: String
        var name: String
        var weight: Double
        var active: Bool
        var payer: String
        var checksum: String
        var clinicianID: String
        var pinned: Bool
        var graceDays: Int
        var status: SkillMixVarianceStatus

        init(code: String, name: String, weight: Double, active: Bool, payer: String, checksum: String, clinicianID: String, pinned: Bool, graceDays: Int, status: SkillMixVarianceStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.active = active
            self.payer = payer
            self.checksum = checksum
            self.clinicianID = clinicianID
            self.pinned = pinned
            self.graceDays = graceDays
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

        func canMoveTo(_ next: SkillMixVarianceStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == SkillMixVarianceStatus.running || next == SkillMixVarianceStatus.done
            case .running:
                return next == SkillMixVarianceStatus.done || next == SkillMixVarianceStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: SkillMixVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("skill mix variance") \(code)"
        }

        func weightedValue() -> Double {
            return ((weight - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixVariance {
            return SkillMixVariance(
                code: code,
                name: name,
                weight: weight,
                active: active,
                payer: payer,
                checksum: checksum,
                clinicianID: clinicianID,
                pinned: pinned,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a skill mix variance in status new.
    static func newSkillMixVariance(_ code: String, name: String) -> SkillMixVariance {
        return SkillMixVariance(
            code: code,
            name: name,
            weight: 0.0,
            active: false,
            payer: "",
            checksum: "",
            clinicianID: "",
            pinned: false,
            graceDays: 0,
            status: SkillMixVarianceStatus.new
        )
    }
}
