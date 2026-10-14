import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim snapshot is in its life cycle.
    enum ClaimSnapshotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A claim snapshot. Its code is unique within a tenant.
    final class ClaimSnapshot {
        var code: String
        var title: String
        var ceiling: Double
        var region: String
        var description: String
        var visitMinutes: Int
        var acuity: Int
        var country: String
        var status: ClaimSnapshotStatus

        init(code: String, title: String, ceiling: Double, region: String, description: String, visitMinutes: Int, acuity: Int, country: String, status: ClaimSnapshotStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.region = region
            self.description = description
            self.visitMinutes = visitMinutes
            self.acuity = acuity
            self.country = country
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

        func canMoveTo(_ next: ClaimSnapshotStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ClaimSnapshotStatus.draining
            case .ready:
                return next == ClaimSnapshotStatus.draining || next == ClaimSnapshotStatus.stopped
            case .draining:
                return next == ClaimSnapshotStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveLoad() -> Double {
            return (Double(acuity) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> ClaimSnapshot {
            return ClaimSnapshot(
                code: code,
                title: title,
                ceiling: ceiling,
                region: region,
                description: description,
                visitMinutes: visitMinutes,
                acuity: acuity,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a claim snapshot in status idle.
    static func newClaimSnapshot(_ code: String, title: String) -> ClaimSnapshot {
        return ClaimSnapshot(
            code: code,
            title: title,
            ceiling: 0.0,
            region: "",
            description: "",
            visitMinutes: 0,
            acuity: 0,
            country: "",
            status: ClaimSnapshotStatus.idle
        )
    }
}
