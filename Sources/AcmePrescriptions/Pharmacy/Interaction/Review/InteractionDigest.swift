import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction digest is in its life cycle.
    enum InteractionDigestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A interaction digest. Its code is unique within a tenant.
    final class InteractionDigest {
        var code: String
        var label: String
        var bed: String
        var checksum: String
        var attempts: Int
        var encounterID: String
        var status: InteractionDigestStatus

        init(code: String, label: String, bed: String, checksum: String, attempts: Int, encounterID: String, status: InteractionDigestStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.checksum = checksum
            self.attempts = attempts
            self.encounterID = encounterID
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

        func canMoveTo(_ next: InteractionDigestStatus) -> Bool {
            switch status {
            case .idle:
                return next == InteractionDigestStatus.ready
            case .warming:
                return next == InteractionDigestStatus.ready || next == InteractionDigestStatus.draining
            case .ready:
                return next == InteractionDigestStatus.stopped
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

        func moveTo(_ next: InteractionDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> InteractionDigest {
            return InteractionDigest(
                code: code,
                label: label,
                bed: bed,
                checksum: checksum,
                attempts: attempts,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a interaction digest in status idle.
    static func newInteractionDigest(_ code: String, label: String) -> InteractionDigest {
        return InteractionDigest(
            code: code,
            label: label,
            bed: "",
            checksum: "",
            attempts: 0,
            encounterID: "",
            status: InteractionDigestStatus.idle
        )
    }
}
