import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix manifest is in its life cycle.
    enum SkillMixManifestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A skill mix manifest. Its code is unique within a tenant.
    final class SkillMixManifest {
        var code: String
        var name: String
        var sequence: Int
        var currency: String
        var threshold: Double
        var status: SkillMixManifestStatus

        init(code: String, name: String, sequence: Int, currency: String, threshold: Double, status: SkillMixManifestStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.currency = currency
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SkillMixManifestStatus) -> Bool {
            switch status {
            case .draft:
                return next == SkillMixManifestStatus.pending || next == SkillMixManifestStatus.suspended
            case .pending:
                return next == SkillMixManifestStatus.suspended
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == SkillMixManifestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("skill mix manifest") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(sequence) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixManifest {
            return SkillMixManifest(
                code: code,
                name: name,
                sequence: sequence,
                currency: currency,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a skill mix manifest in status draft.
    static func newSkillMixManifest(_ code: String, name: String) -> SkillMixManifest {
        return SkillMixManifest(
            code: code,
            name: name,
            sequence: 0,
            currency: "",
            threshold: 0.0,
            status: SkillMixManifestStatus.draft
        )
    }
}
