import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a tiered isolation group is in its life cycle.
    enum TieredIsolationGroupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a tiered isolation group and its current status.
    final class TieredIsolationGroup {
        var code: String
        var name: String
        var segment: String
        var score: Double
        var contactEmail: String
        var facility: String
        var visitMinutes: Int
        var priority: Int
        var region: String
        var checksum: String
        var bed: String
        var status: TieredIsolationGroupStatus

        init(code: String, name: String, segment: String, score: Double, contactEmail: String, facility: String, visitMinutes: Int, priority: Int, region: String, checksum: String, bed: String, status: TieredIsolationGroupStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.score = score
            self.contactEmail = contactEmail
            self.facility = facility
            self.visitMinutes = visitMinutes
            self.priority = priority
            self.region = region
            self.checksum = checksum
            self.bed = bed
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

        func canMoveTo(_ next: TieredIsolationGroupStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == TieredIsolationGroupStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredIsolationGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered isolation group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("tiered isolation group") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(priority) + score) * 100).rounded() / 100
        }

        func copyValue() -> TieredIsolationGroup {
            return TieredIsolationGroup(
                code: code,
                name: name,
                segment: segment,
                score: score,
                contactEmail: contactEmail,
                facility: facility,
                visitMinutes: visitMinutes,
                priority: priority,
                region: region,
                checksum: checksum,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a tiered isolation group in status requested.
    static func newTieredIsolationGroup(_ code: String, name: String) -> TieredIsolationGroup {
        return TieredIsolationGroup(
            code: code,
            name: name,
            segment: "",
            score: 0.0,
            contactEmail: "",
            facility: "",
            visitMinutes: 0,
            priority: 0,
            region: "",
            checksum: "",
            bed: "",
            status: TieredIsolationGroupStatus.requested
        )
    }
}
