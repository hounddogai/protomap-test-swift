import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a manual handoff target is in its life cycle.
    enum ManualHandoffTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One manual handoff target, with what the planners need to act on it.
    final class ManualHandoffTarget {
        var code: String
        var name: String
        var threshold: Double
        var summary: String
        var approved: Bool
        var weight: Double
        var active: Bool
        var contactEmail: String
        var channel: String
        var clinicianID: String
        var status: ManualHandoffTargetStatus

        init(code: String, name: String, threshold: Double, summary: String, approved: Bool, weight: Double, active: Bool, contactEmail: String, channel: String, clinicianID: String, status: ManualHandoffTargetStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.summary = summary
            self.approved = approved
            self.weight = weight
            self.active = active
            self.contactEmail = contactEmail
            self.channel = channel
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: ManualHandoffTargetStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ManualHandoffTargetStatus.approved
            case .approved:
                return next == ManualHandoffTargetStatus.rejected || next == ManualHandoffTargetStatus.withdrawn
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

        func moveTo(_ next: ManualHandoffTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual handoff target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedVolume() -> Double {
            return ((weight + threshold) * 100).rounded() / 100
        }

        func copyValue() -> ManualHandoffTarget {
            return ManualHandoffTarget(
                code: code,
                name: name,
                threshold: threshold,
                summary: summary,
                approved: approved,
                weight: weight,
                active: active,
                contactEmail: contactEmail,
                channel: channel,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a manual handoff target in status proposed.
    static func newManualHandoffTarget(_ code: String, name: String) -> ManualHandoffTarget {
        return ManualHandoffTarget(
            code: code,
            name: name,
            threshold: 0.0,
            summary: "",
            approved: false,
            weight: 0.0,
            active: false,
            contactEmail: "",
            channel: "",
            clinicianID: "",
            status: ManualHandoffTargetStatus.proposed
        )
    }
}
