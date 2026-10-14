import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary skill mix preference is in its life cycle.
    enum PrimarySkillMixPreferenceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a primary skill mix preference and its current status.
    final class PrimarySkillMixPreference {
        var code: String
        var label: String
        var score: Double
        var windowDays: Int
        var bed: String
        var source: String
        var copay: Double
        var category: String
        var visible: Bool
        var status: PrimarySkillMixPreferenceStatus

        init(code: String, label: String, score: Double, windowDays: Int, bed: String, source: String, copay: Double, category: String, visible: Bool, status: PrimarySkillMixPreferenceStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.windowDays = windowDays
            self.bed = bed
            self.source = source
            self.copay = copay
            self.category = category
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimarySkillMixPreferenceStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PrimarySkillMixPreferenceStatus.approved || next == PrimarySkillMixPreferenceStatus.rejected
            case .approved:
                return next == PrimarySkillMixPreferenceStatus.rejected || next == PrimarySkillMixPreferenceStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: PrimarySkillMixPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary skill mix preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedTotal() -> Double {
            return (Double(windowDays) * score * 100).rounded() / 100
        }

        func copyValue() -> PrimarySkillMixPreference {
            return PrimarySkillMixPreference(
                code: code,
                label: label,
                score: score,
                windowDays: windowDays,
                bed: bed,
                source: source,
                copay: copay,
                category: category,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a primary skill mix preference in status proposed.
    static func newPrimarySkillMixPreference(_ code: String, label: String) -> PrimarySkillMixPreference {
        return PrimarySkillMixPreference(
            code: code,
            label: label,
            score: 0.0,
            windowDays: 0,
            bed: "",
            source: "",
            copay: 0.0,
            category: "",
            visible: false,
            status: PrimarySkillMixPreferenceStatus.proposed
        )
    }
}
