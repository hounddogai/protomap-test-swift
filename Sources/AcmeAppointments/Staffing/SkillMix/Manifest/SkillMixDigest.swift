import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix digest is in its life cycle.
    enum SkillMixDigestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A skill mix digest. Its code is unique within a tenant.
    final class SkillMixDigest {
        var code: String
        var label: String
        var maximum: Double
        var ownerID: String
        var visible: Bool
        var tags: [String]
        var segment: String
        var patientRef: String
        var channel: String
        var status: SkillMixDigestStatus

        init(code: String, label: String, maximum: Double, ownerID: String, visible: Bool, tags: [String], segment: String, patientRef: String, channel: String, status: SkillMixDigestStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.ownerID = ownerID
            self.visible = visible
            self.tags = tags
            self.segment = segment
            self.patientRef = patientRef
            self.channel = channel
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SkillMixDigestStatus) -> Bool {
            switch status {
            case .requested:
                return next == SkillMixDigestStatus.revoked
            case .granted:
                return next == SkillMixDigestStatus.revoked
            case .revoked:
                return next == SkillMixDigestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("skill mix digest") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> SkillMixDigest {
            return SkillMixDigest(
                code: code,
                label: label,
                maximum: maximum,
                ownerID: ownerID,
                visible: visible,
                tags: tags,
                segment: segment,
                patientRef: patientRef,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a skill mix digest in status requested.
    static func newSkillMixDigest(_ code: String, label: String) -> SkillMixDigest {
        return SkillMixDigest(
            code: code,
            label: label,
            maximum: 0.0,
            ownerID: "",
            visible: false,
            tags: [],
            segment: "",
            patientRef: "",
            channel: "",
            status: SkillMixDigestStatus.requested
        )
    }
}
