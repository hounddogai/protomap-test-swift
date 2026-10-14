import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier group is in its life cycle.
    enum CourierGroupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A courier group. Its code is unique within a tenant.
    final class CourierGroup {
        var code: String
        var title: String
        var sequence: Int
        var encounterID: String
        var startsAt: Int
        var bed: String
        var limit: Int
        var source: String
        var attempts: Int
        var weight: Double
        var status: CourierGroupStatus

        init(code: String, title: String, sequence: Int, encounterID: String, startsAt: Int, bed: String, limit: Int, source: String, attempts: Int, weight: Double, status: CourierGroupStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.encounterID = encounterID
            self.startsAt = startsAt
            self.bed = bed
            self.limit = limit
            self.source = source
            self.attempts = attempts
            self.weight = weight
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CourierGroupStatus) -> Bool {
            switch status {
            case .draft:
                return next == CourierGroupStatus.active
            case .pending:
                return next == CourierGroupStatus.active || next == CourierGroupStatus.suspended
            case .active:
                return next == CourierGroupStatus.suspended || next == CourierGroupStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: CourierGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netVolume() -> Double {
            return (Double(attempts) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> CourierGroup {
            return CourierGroup(
                code: code,
                title: title,
                sequence: sequence,
                encounterID: encounterID,
                startsAt: startsAt,
                bed: bed,
                limit: limit,
                source: source,
                attempts: attempts,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a courier group in status draft.
    static func newCourierGroup(_ code: String, title: String) -> CourierGroup {
        return CourierGroup(
            code: code,
            title: title,
            sequence: 0,
            encounterID: "",
            startsAt: 0,
            bed: "",
            limit: 0,
            source: "",
            attempts: 0,
            weight: 0.0,
            status: CourierGroupStatus.draft
        )
    }
}
