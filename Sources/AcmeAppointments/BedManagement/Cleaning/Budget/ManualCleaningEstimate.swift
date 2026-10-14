import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual cleaning estimate is in its life cycle.
    enum ManualCleaningEstimateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a manual cleaning estimate and its current status.
    final class ManualCleaningEstimate {
        var code: String
        var name: String
        var refills: Int
        var contactEmail: String
        var batchSize: Int
        var notes: String
        var status: ManualCleaningEstimateStatus

        init(code: String, name: String, refills: Int, contactEmail: String, batchSize: Int, notes: String, status: ManualCleaningEstimateStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.contactEmail = contactEmail
            self.batchSize = batchSize
            self.notes = notes
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

        func canMoveTo(_ next: ManualCleaningEstimateStatus) -> Bool {
            switch status {
            case .planned:
                return next == ManualCleaningEstimateStatus.cancelled
            case .scheduled:
                return next == ManualCleaningEstimateStatus.completed || next == ManualCleaningEstimateStatus.cancelled
            case .inProgress:
                return next == ManualCleaningEstimateStatus.completed || next == ManualCleaningEstimateStatus.cancelled
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

        func moveTo(_ next: ManualCleaningEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual cleaning estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedValue() -> Double {
            return (Double(refills) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> ManualCleaningEstimate {
            return ManualCleaningEstimate(
                code: code,
                name: name,
                refills: refills,
                contactEmail: contactEmail,
                batchSize: batchSize,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual cleaning estimate in status planned.
    static func newManualCleaningEstimate(_ code: String, name: String) -> ManualCleaningEstimate {
        return ManualCleaningEstimate(
            code: code,
            name: name,
            refills: 0,
            contactEmail: "",
            batchSize: 0,
            notes: "",
            status: ManualCleaningEstimateStatus.planned
        )
    }
}
