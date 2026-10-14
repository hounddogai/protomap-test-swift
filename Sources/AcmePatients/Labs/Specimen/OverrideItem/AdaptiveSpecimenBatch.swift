import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive specimen batch is in its life cycle.
    enum AdaptiveSpecimenBatchStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A adaptive specimen batch. Its code is unique within a tenant.
    final class AdaptiveSpecimenBatch {
        var code: String
        var name: String
        var priority: Int
        var notes: String
        var checksum: String
        var dosageMg: Double
        var score: Double
        var expiresAt: Int
        var procedureCode: String
        var clinicianID: String
        var status: AdaptiveSpecimenBatchStatus

        init(code: String, name: String, priority: Int, notes: String, checksum: String, dosageMg: Double, score: Double, expiresAt: Int, procedureCode: String, clinicianID: String, status: AdaptiveSpecimenBatchStatus) {
            self.code = code
            self.name = name
            self.priority = priority
            self.notes = notes
            self.checksum = checksum
            self.dosageMg = dosageMg
            self.score = score
            self.expiresAt = expiresAt
            self.procedureCode = procedureCode
            self.clinicianID = clinicianID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveSpecimenBatchStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == AdaptiveSpecimenBatchStatus.inProgress
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == AdaptiveSpecimenBatchStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveSpecimenBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive specimen batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("adaptive specimen batch") \(code)"
        }

        func netExposure() -> Double {
            return ((dosageMg + score) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveSpecimenBatch {
            return AdaptiveSpecimenBatch(
                code: code,
                name: name,
                priority: priority,
                notes: notes,
                checksum: checksum,
                dosageMg: dosageMg,
                score: score,
                expiresAt: expiresAt,
                procedureCode: procedureCode,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive specimen batch in status planned.
    static func newAdaptiveSpecimenBatch(_ code: String, name: String) -> AdaptiveSpecimenBatch {
        return AdaptiveSpecimenBatch(
            code: code,
            name: name,
            priority: 0,
            notes: "",
            checksum: "",
            dosageMg: 0.0,
            score: 0.0,
            expiresAt: 0,
            procedureCode: "",
            clinicianID: "",
            status: AdaptiveSpecimenBatchStatus.planned
        )
    }
}
