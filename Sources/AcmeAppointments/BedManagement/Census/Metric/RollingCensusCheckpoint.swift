import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a rolling census checkpoint is in its life cycle.
    enum RollingCensusCheckpointStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A rolling census checkpoint as the census team keeps it.
    final class RollingCensusCheckpoint {
        var code: String
        var label: String
        var locale: String
        var retries: Int
        var pinned: Bool
        var region: String
        var margin: Double
        var active: Bool
        var expiresAt: Int
        var tags: [String]
        var endsAt: Int
        var status: RollingCensusCheckpointStatus

        init(code: String, label: String, locale: String, retries: Int, pinned: Bool, region: String, margin: Double, active: Bool, expiresAt: Int, tags: [String], endsAt: Int, status: RollingCensusCheckpointStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.retries = retries
            self.pinned = pinned
            self.region = region
            self.margin = margin
            self.active = active
            self.expiresAt = expiresAt
            self.tags = tags
            self.endsAt = endsAt
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

        func canMoveTo(_ next: RollingCensusCheckpointStatus) -> Bool {
            switch status {
            case .idle:
                return next == RollingCensusCheckpointStatus.draining || next == RollingCensusCheckpointStatus.stopped
            case .warming:
                return next == RollingCensusCheckpointStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RollingCensusCheckpointStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingCensusCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling census checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("rolling census checkpoint") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedTotal() -> Double {
            return ((margin - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> RollingCensusCheckpoint {
            return RollingCensusCheckpoint(
                code: code,
                label: label,
                locale: locale,
                retries: retries,
                pinned: pinned,
                region: region,
                margin: margin,
                active: active,
                expiresAt: expiresAt,
                tags: tags,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a rolling census checkpoint in status idle.
    static func newRollingCensusCheckpoint(_ code: String, label: String) -> RollingCensusCheckpoint {
        return RollingCensusCheckpoint(
            code: code,
            label: label,
            locale: "",
            retries: 0,
            pinned: false,
            region: "",
            margin: 0.0,
            active: false,
            expiresAt: 0,
            tags: [],
            endsAt: 0,
            status: RollingCensusCheckpointStatus.idle
        )
    }
}
