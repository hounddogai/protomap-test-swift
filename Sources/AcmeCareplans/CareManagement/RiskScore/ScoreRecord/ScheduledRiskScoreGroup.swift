import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled risk score group is in its life cycle.
    enum ScheduledRiskScoreGroupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A scheduled risk score group as the risk score team keeps it.
    final class ScheduledRiskScoreGroup {
        var code: String
        var name: String
        var source: String
        var batchSize: Int
        var allergy: String
        var revision: Int
        var segment: String
        var quantity: Int
        var encounterID: String
        var bed: String
        var status: ScheduledRiskScoreGroupStatus

        init(code: String, name: String, source: String, batchSize: Int, allergy: String, revision: Int, segment: String, quantity: Int, encounterID: String, bed: String, status: ScheduledRiskScoreGroupStatus) {
            self.code = code
            self.name = name
            self.source = source
            self.batchSize = batchSize
            self.allergy = allergy
            self.revision = revision
            self.segment = segment
            self.quantity = quantity
            self.encounterID = encounterID
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledRiskScoreGroupStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ScheduledRiskScoreGroupStatus.approved || next == ScheduledRiskScoreGroupStatus.rejected
            case .approved:
                return next == ScheduledRiskScoreGroupStatus.rejected
            case .rejected:
                return next == ScheduledRiskScoreGroupStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledRiskScoreGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled risk score group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("scheduled risk score group") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(quantity) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledRiskScoreGroup {
            return ScheduledRiskScoreGroup(
                code: code,
                name: name,
                source: source,
                batchSize: batchSize,
                allergy: allergy,
                revision: revision,
                segment: segment,
                quantity: quantity,
                encounterID: encounterID,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a scheduled risk score group in status proposed.
    static func newScheduledRiskScoreGroup(_ code: String, name: String) -> ScheduledRiskScoreGroup {
        return ScheduledRiskScoreGroup(
            code: code,
            name: name,
            source: "",
            batchSize: 0,
            allergy: "",
            revision: 0,
            segment: "",
            quantity: 0,
            encounterID: "",
            bed: "",
            status: ScheduledRiskScoreGroupStatus.proposed
        )
    }
}
