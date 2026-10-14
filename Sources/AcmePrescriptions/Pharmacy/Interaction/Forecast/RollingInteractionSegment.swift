import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a rolling interaction segment is in its life cycle.
    enum RollingInteractionSegmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A rolling interaction segment as the interaction team keeps it.
    final class RollingInteractionSegment {
        var code: String
        var label: String
        var description: String
        var capacity: Int
        var weight: Double
        var endsAt: Int
        var startsAt: Int
        var expiresAt: Int
        var status: RollingInteractionSegmentStatus

        init(code: String, label: String, description: String, capacity: Int, weight: Double, endsAt: Int, startsAt: Int, expiresAt: Int, status: RollingInteractionSegmentStatus) {
            self.code = code
            self.label = label
            self.description = description
            self.capacity = capacity
            self.weight = weight
            self.endsAt = endsAt
            self.startsAt = startsAt
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: RollingInteractionSegmentStatus) -> Bool {
            switch status {
            case .requested:
                return next == RollingInteractionSegmentStatus.revoked || next == RollingInteractionSegmentStatus.expired
            case .granted:
                return next == RollingInteractionSegmentStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: RollingInteractionSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling interaction segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netValue() -> Double {
            return (Double(expiresAt) * weight * 100).rounded() / 100
        }

        func copyValue() -> RollingInteractionSegment {
            return RollingInteractionSegment(
                code: code,
                label: label,
                description: description,
                capacity: capacity,
                weight: weight,
                endsAt: endsAt,
                startsAt: startsAt,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling interaction segment in status requested.
    static func newRollingInteractionSegment(_ code: String, label: String) -> RollingInteractionSegment {
        return RollingInteractionSegment(
            code: code,
            label: label,
            description: "",
            capacity: 0,
            weight: 0.0,
            endsAt: 0,
            startsAt: 0,
            expiresAt: 0,
            status: RollingInteractionSegmentStatus.requested
        )
    }
}
