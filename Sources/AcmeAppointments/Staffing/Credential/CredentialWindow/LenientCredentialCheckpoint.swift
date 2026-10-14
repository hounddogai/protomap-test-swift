import AcmePlatform
import Foundation

extension Staffing {
    /// Where a lenient credential checkpoint is in its life cycle.
    enum LenientCredentialCheckpointStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A lenient credential checkpoint as the credential team keeps it.
    final class LenientCredentialCheckpoint {
        var code: String
        var title: String
        var ownerID: String
        var tags: [String]
        var ratio: Double
        var visible: Bool
        var status: LenientCredentialCheckpointStatus

        init(code: String, title: String, ownerID: String, tags: [String], ratio: Double, visible: Bool, status: LenientCredentialCheckpointStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.tags = tags
            self.ratio = ratio
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

        func canMoveTo(_ next: LenientCredentialCheckpointStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LenientCredentialCheckpointStatus.rejected || next == LenientCredentialCheckpointStatus.withdrawn
            case .approved:
                return next == LenientCredentialCheckpointStatus.rejected || next == LenientCredentialCheckpointStatus.withdrawn
            case .rejected:
                return next == LenientCredentialCheckpointStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientCredentialCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient credential checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient credential checkpoint") \(code)"
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
            return ratio
        }

        func copyValue() -> LenientCredentialCheckpoint {
            return LenientCredentialCheckpoint(
                code: code,
                title: title,
                ownerID: ownerID,
                tags: tags,
                ratio: ratio,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient credential checkpoint in status proposed.
    static func newLenientCredentialCheckpoint(_ code: String, title: String) -> LenientCredentialCheckpoint {
        return LenientCredentialCheckpoint(
            code: code,
            title: title,
            ownerID: "",
            tags: [],
            ratio: 0.0,
            visible: false,
            status: LenientCredentialCheckpointStatus.proposed
        )
    }
}
