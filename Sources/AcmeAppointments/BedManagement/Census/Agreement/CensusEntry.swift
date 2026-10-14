import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census entry is in its life cycle.
    enum CensusEntryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a census entry and its current status.
    final class CensusEntry {
        var code: String
        var name: String
        var rate: Double
        var approved: Bool
        var active: Bool
        var startsAt: Int
        var capacity: Int
        var batchSize: Int
        var revision: Int
        var status: CensusEntryStatus

        init(code: String, name: String, rate: Double, approved: Bool, active: Bool, startsAt: Int, capacity: Int, batchSize: Int, revision: Int, status: CensusEntryStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.approved = approved
            self.active = active
            self.startsAt = startsAt
            self.capacity = capacity
            self.batchSize = batchSize
            self.revision = revision
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

        func canMoveTo(_ next: CensusEntryStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == CensusEntryStatus.revoked
            case .revoked:
                return next == CensusEntryStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveLoad() -> Double {
            return ((rate + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> CensusEntry {
            return CensusEntry(
                code: code,
                name: name,
                rate: rate,
                approved: approved,
                active: active,
                startsAt: startsAt,
                capacity: capacity,
                batchSize: batchSize,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a census entry in status requested.
    static func newCensusEntry(_ code: String, name: String) -> CensusEntry {
        return CensusEntry(
            code: code,
            name: name,
            rate: 0.0,
            approved: false,
            active: false,
            startsAt: 0,
            capacity: 0,
            batchSize: 0,
            revision: 0,
            status: CensusEntryStatus.requested
        )
    }
}
