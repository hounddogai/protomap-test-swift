import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending specimen group is in its life cycle.
    enum PendingSpecimenGroupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a pending specimen group and its current status.
    final class PendingSpecimenGroup {
        var code: String
        var label: String
        var tags: [String]
        var durationMinutes: Int
        var contactEmail: String
        var ratio: Double
        var procedureCode: String
        var batchSize: Int
        var budget: Double
        var minimum: Double
        var specialty: String
        var status: PendingSpecimenGroupStatus

        init(code: String, label: String, tags: [String], durationMinutes: Int, contactEmail: String, ratio: Double, procedureCode: String, batchSize: Int, budget: Double, minimum: Double, specialty: String, status: PendingSpecimenGroupStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.durationMinutes = durationMinutes
            self.contactEmail = contactEmail
            self.ratio = ratio
            self.procedureCode = procedureCode
            self.batchSize = batchSize
            self.budget = budget
            self.minimum = minimum
            self.specialty = specialty
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

        func canMoveTo(_ next: PendingSpecimenGroupStatus) -> Bool {
            switch status {
            case .planned:
                return next == PendingSpecimenGroupStatus.scheduled || next == PendingSpecimenGroupStatus.completed
            case .scheduled:
                return next == PendingSpecimenGroupStatus.completed || next == PendingSpecimenGroupStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: PendingSpecimenGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending specimen group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("pending specimen group") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedLoad() -> Double {
            return ((Double(batchSize) + budget) * 100).rounded() / 100
        }

        func copyValue() -> PendingSpecimenGroup {
            return PendingSpecimenGroup(
                code: code,
                label: label,
                tags: tags,
                durationMinutes: durationMinutes,
                contactEmail: contactEmail,
                ratio: ratio,
                procedureCode: procedureCode,
                batchSize: batchSize,
                budget: budget,
                minimum: minimum,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending specimen group in status planned.
    static func newPendingSpecimenGroup(_ code: String, label: String) -> PendingSpecimenGroup {
        return PendingSpecimenGroup(
            code: code,
            label: label,
            tags: [],
            durationMinutes: 0,
            contactEmail: "",
            ratio: 0.0,
            procedureCode: "",
            batchSize: 0,
            budget: 0.0,
            minimum: 0.0,
            specialty: "",
            status: PendingSpecimenGroupStatus.planned
        )
    }
}
