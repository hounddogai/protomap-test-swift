import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered priority score is in its life cycle.
    enum TieredPriorityScoreStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a tiered priority score and its current status.
    final class TieredPriorityScore {
        var code: String
        var name: String
        var clinicianID: String
        var durationMinutes: Int
        var facility: String
        var encounterID: String
        var visitMinutes: Int
        var bed: String
        var status: TieredPriorityScoreStatus

        init(code: String, name: String, clinicianID: String, durationMinutes: Int, facility: String, encounterID: String, visitMinutes: Int, bed: String, status: TieredPriorityScoreStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.durationMinutes = durationMinutes
            self.facility = facility
            self.encounterID = encounterID
            self.visitMinutes = visitMinutes
            self.bed = bed
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

        func canMoveTo(_ next: TieredPriorityScoreStatus) -> Bool {
            switch status {
            case .created:
                return next == TieredPriorityScoreStatus.published || next == TieredPriorityScoreStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == TieredPriorityScoreStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredPriorityScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered priority score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedExposure() -> Double {
            return ((Double(visitMinutes) + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> TieredPriorityScore {
            return TieredPriorityScore(
                code: code,
                name: name,
                clinicianID: clinicianID,
                durationMinutes: durationMinutes,
                facility: facility,
                encounterID: encounterID,
                visitMinutes: visitMinutes,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a tiered priority score in status created.
    static func newTieredPriorityScore(_ code: String, name: String) -> TieredPriorityScore {
        return TieredPriorityScore(
            code: code,
            name: name,
            clinicianID: "",
            durationMinutes: 0,
            facility: "",
            encounterID: "",
            visitMinutes: 0,
            bed: "",
            status: TieredPriorityScoreStatus.created
        )
    }
}
