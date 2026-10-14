import AcmePlatform
import Foundation

extension Staffing {
    /// Where a adaptive skill mix manifest is in its life cycle.
    enum AdaptiveSkillMixManifestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A adaptive skill mix manifest as the skill mix team keeps it.
    final class AdaptiveSkillMixManifest {
        var code: String
        var title: String
        var endsAt: Int
        var name: String
        var approved: Bool
        var status: AdaptiveSkillMixManifestStatus

        init(code: String, title: String, endsAt: Int, name: String, approved: Bool, status: AdaptiveSkillMixManifestStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.name = name
            self.approved = approved
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

        func canMoveTo(_ next: AdaptiveSkillMixManifestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == AdaptiveSkillMixManifestStatus.running
            case .running:
                return next == AdaptiveSkillMixManifestStatus.done || next == AdaptiveSkillMixManifestStatus.failed
            case .done:
                return next == AdaptiveSkillMixManifestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveSkillMixManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive skill mix manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("adaptive skill mix manifest") \(code)"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> AdaptiveSkillMixManifest {
            return AdaptiveSkillMixManifest(
                code: code,
                title: title,
                endsAt: endsAt,
                name: name,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive skill mix manifest in status new.
    static func newAdaptiveSkillMixManifest(_ code: String, title: String) -> AdaptiveSkillMixManifest {
        return AdaptiveSkillMixManifest(
            code: code,
            title: title,
            endsAt: 0,
            name: "",
            approved: false,
            status: AdaptiveSkillMixManifestStatus.new
        )
    }
}
