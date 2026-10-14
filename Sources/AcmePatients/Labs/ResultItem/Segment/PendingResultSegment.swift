import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending result segment is in its life cycle.
    enum PendingResultSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A pending result segment as the result team keeps it.
    final class PendingResultSegment {
        var code: String
        var title: String
        var ownerID: String
        var segment: String
        var priority: Int
        var startsAt: Int
        var diagnosisCode: String
        var revision: Int
        var unit: String
        var description: String
        var endsAt: Int
        var status: PendingResultSegmentStatus

        init(code: String, title: String, ownerID: String, segment: String, priority: Int, startsAt: Int, diagnosisCode: String, revision: Int, unit: String, description: String, endsAt: Int, status: PendingResultSegmentStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.segment = segment
            self.priority = priority
            self.startsAt = startsAt
            self.diagnosisCode = diagnosisCode
            self.revision = revision
            self.unit = unit
            self.description = description
            self.endsAt = endsAt
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

        func canMoveTo(_ next: PendingResultSegmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == PendingResultSegmentStatus.pending
            case .pending:
                return next == PendingResultSegmentStatus.active || next == PendingResultSegmentStatus.closed
            case .active:
                return next == PendingResultSegmentStatus.closed
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

        func moveTo(_ next: PendingResultSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending result segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedTotal() -> Double {
            return ((Double(endsAt) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> PendingResultSegment {
            return PendingResultSegment(
                code: code,
                title: title,
                ownerID: ownerID,
                segment: segment,
                priority: priority,
                startsAt: startsAt,
                diagnosisCode: diagnosisCode,
                revision: revision,
                unit: unit,
                description: description,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a pending result segment in status draft.
    static func newPendingResultSegment(_ code: String, title: String) -> PendingResultSegment {
        return PendingResultSegment(
            code: code,
            title: title,
            ownerID: "",
            segment: "",
            priority: 0,
            startsAt: 0,
            diagnosisCode: "",
            revision: 0,
            unit: "",
            description: "",
            endsAt: 0,
            status: PendingResultSegmentStatus.draft
        )
    }
}
