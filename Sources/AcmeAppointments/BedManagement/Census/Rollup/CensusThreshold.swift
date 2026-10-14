import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census threshold is in its life cycle.
    enum CensusThresholdStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a census threshold and its current status.
    final class CensusThreshold {
        var code: String
        var title: String
        var revision: Int
        var clinicianID: String
        var priority: Int
        var endsAt: Int
        var retries: Int
        var status: CensusThresholdStatus

        init(code: String, title: String, revision: Int, clinicianID: String, priority: Int, endsAt: Int, retries: Int, status: CensusThresholdStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.clinicianID = clinicianID
            self.priority = priority
            self.endsAt = endsAt
            self.retries = retries
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

        func canMoveTo(_ next: CensusThresholdStatus) -> Bool {
            switch status {
            case .draft:
                return next == CensusThresholdStatus.suspended
            case .pending:
                return next == CensusThresholdStatus.active
            case .active:
                return next == CensusThresholdStatus.closed
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

        func moveTo(_ next: CensusThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("census threshold") \(code)"
        }

        func weightedExposure() -> Double {
            return ((Double(priority) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> CensusThreshold {
            return CensusThreshold(
                code: code,
                title: title,
                revision: revision,
                clinicianID: clinicianID,
                priority: priority,
                endsAt: endsAt,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a census threshold in status draft.
    static func newCensusThreshold(_ code: String, title: String) -> CensusThreshold {
        return CensusThreshold(
            code: code,
            title: title,
            revision: 0,
            clinicianID: "",
            priority: 0,
            endsAt: 0,
            retries: 0,
            status: CensusThresholdStatus.draft
        )
    }
}
