import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen exception is in its life cycle.
    enum SpecimenExceptionStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A specimen exception as the specimen team keeps it.
    final class SpecimenException {
        var code: String
        var label: String
        var bed: String
        var region: String
        var batchSize: Int
        var summary: String
        var notes: String
        var archived: Bool
        var minimum: Double
        var retries: Int
        var status: SpecimenExceptionStatus

        init(code: String, label: String, bed: String, region: String, batchSize: Int, summary: String, notes: String, archived: Bool, minimum: Double, retries: Int, status: SpecimenExceptionStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.region = region
            self.batchSize = batchSize
            self.summary = summary
            self.notes = notes
            self.archived = archived
            self.minimum = minimum
            self.retries = retries
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

        func canMoveTo(_ next: SpecimenExceptionStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SpecimenExceptionStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == SpecimenExceptionStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedTotal() -> Double {
            return ((Double(batchSize) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenException {
            return SpecimenException(
                code: code,
                label: label,
                bed: bed,
                region: region,
                batchSize: batchSize,
                summary: summary,
                notes: notes,
                archived: archived,
                minimum: minimum,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a specimen exception in status proposed.
    static func newSpecimenException(_ code: String, label: String) -> SpecimenException {
        return SpecimenException(
            code: code,
            label: label,
            bed: "",
            region: "",
            batchSize: 0,
            summary: "",
            notes: "",
            archived: false,
            minimum: 0.0,
            retries: 0,
            status: SpecimenExceptionStatus.proposed
        )
    }
}
