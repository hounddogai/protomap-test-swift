import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a capped dispense checkpoint is in its life cycle.
    enum CappedDispenseCheckpointStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A capped dispense checkpoint as the dispense team keeps it.
    final class CappedDispenseCheckpoint {
        var code: String
        var title: String
        var payer: String
        var unit: String
        var archived: Bool
        var procedureCode: String
        var contactEmail: String
        var score: Double
        var status: CappedDispenseCheckpointStatus

        init(code: String, title: String, payer: String, unit: String, archived: Bool, procedureCode: String, contactEmail: String, score: Double, status: CappedDispenseCheckpointStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.unit = unit
            self.archived = archived
            self.procedureCode = procedureCode
            self.contactEmail = contactEmail
            self.score = score
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

        func canMoveTo(_ next: CappedDispenseCheckpointStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == CappedDispenseCheckpointStatus.published || next == CappedDispenseCheckpointStatus.retired
            case .published:
                return next == CappedDispenseCheckpointStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedDispenseCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped dispense checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped dispense checkpoint") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> CappedDispenseCheckpoint {
            return CappedDispenseCheckpoint(
                code: code,
                title: title,
                payer: payer,
                unit: unit,
                archived: archived,
                procedureCode: procedureCode,
                contactEmail: contactEmail,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a capped dispense checkpoint in status created.
    static func newCappedDispenseCheckpoint(_ code: String, title: String) -> CappedDispenseCheckpoint {
        return CappedDispenseCheckpoint(
            code: code,
            title: title,
            payer: "",
            unit: "",
            archived: false,
            procedureCode: "",
            contactEmail: "",
            score: 0.0,
            status: CappedDispenseCheckpointStatus.created
        )
    }
}
