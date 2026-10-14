import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a capped census segment is in its life cycle.
    enum CappedCensusSegmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A capped census segment. Its code is unique within a tenant.
    final class CappedCensusSegment {
        var code: String
        var name: String
        var endsAt: Int
        var sequence: Int
        var budget: Double
        var expiresAt: Int
        var channel: String
        var ownerID: String
        var updatedAt: Int
        var locale: String
        var encounterID: String
        var status: CappedCensusSegmentStatus

        init(code: String, name: String, endsAt: Int, sequence: Int, budget: Double, expiresAt: Int, channel: String, ownerID: String, updatedAt: Int, locale: String, encounterID: String, status: CappedCensusSegmentStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.sequence = sequence
            self.budget = budget
            self.expiresAt = expiresAt
            self.channel = channel
            self.ownerID = ownerID
            self.updatedAt = updatedAt
            self.locale = locale
            self.encounterID = encounterID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedCensusSegmentStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == CappedCensusSegmentStatus.reopened
            case .reopened:
                return next == CappedCensusSegmentStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedCensusSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped census segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netExposure() -> Double {
            return ((Double(endsAt) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> CappedCensusSegment {
            return CappedCensusSegment(
                code: code,
                name: name,
                endsAt: endsAt,
                sequence: sequence,
                budget: budget,
                expiresAt: expiresAt,
                channel: channel,
                ownerID: ownerID,
                updatedAt: updatedAt,
                locale: locale,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped census segment in status open.
    static func newCappedCensusSegment(_ code: String, name: String) -> CappedCensusSegment {
        return CappedCensusSegment(
            code: code,
            name: name,
            endsAt: 0,
            sequence: 0,
            budget: 0.0,
            expiresAt: 0,
            channel: "",
            ownerID: "",
            updatedAt: 0,
            locale: "",
            encounterID: "",
            status: CappedCensusSegmentStatus.`open`
        )
    }
}
