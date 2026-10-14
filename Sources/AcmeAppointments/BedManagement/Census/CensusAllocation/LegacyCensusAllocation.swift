import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a legacy census allocation is in its life cycle.
    enum LegacyCensusAllocationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a legacy census allocation and its current status.
    final class LegacyCensusAllocation {
        var code: String
        var title: String
        var encounterID: String
        var checksum: String
        var endsAt: Int
        var threshold: Double
        var status: LegacyCensusAllocationStatus

        init(code: String, title: String, encounterID: String, checksum: String, endsAt: Int, threshold: Double, status: LegacyCensusAllocationStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.checksum = checksum
            self.endsAt = endsAt
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyCensusAllocationStatus) -> Bool {
            switch status {
            case .created:
                return next == LegacyCensusAllocationStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: LegacyCensusAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy census allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedTotal() -> Double {
            return ((threshold + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyCensusAllocation {
            return LegacyCensusAllocation(
                code: code,
                title: title,
                encounterID: encounterID,
                checksum: checksum,
                endsAt: endsAt,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy census allocation in status created.
    static func newLegacyCensusAllocation(_ code: String, title: String) -> LegacyCensusAllocation {
        return LegacyCensusAllocation(
            code: code,
            title: title,
            encounterID: "",
            checksum: "",
            endsAt: 0,
            threshold: 0.0,
            status: LegacyCensusAllocationStatus.created
        )
    }
}
