import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a batched formulary bundle is in its life cycle.
    enum BatchedFormularyBundleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A batched formulary bundle. Its code is unique within a tenant.
    final class BatchedFormularyBundle {
        var code: String
        var title: String
        var capacity: Int
        var clinicianID: String
        var name: String
        var diagnosisCode: String
        var discount: Double
        var facility: String
        var retries: Int
        var status: BatchedFormularyBundleStatus

        init(code: String, title: String, capacity: Int, clinicianID: String, name: String, diagnosisCode: String, discount: Double, facility: String, retries: Int, status: BatchedFormularyBundleStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.clinicianID = clinicianID
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.discount = discount
            self.facility = facility
            self.retries = retries
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedFormularyBundleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == BatchedFormularyBundleStatus.resolved || next == BatchedFormularyBundleStatus.archived
            case .inReview:
                return next == BatchedFormularyBundleStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == BatchedFormularyBundleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedFormularyBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched formulary bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched formulary bundle") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((Double(retries) + discount) * 100).rounded() / 100
        }

        func copyValue() -> BatchedFormularyBundle {
            return BatchedFormularyBundle(
                code: code,
                title: title,
                capacity: capacity,
                clinicianID: clinicianID,
                name: name,
                diagnosisCode: diagnosisCode,
                discount: discount,
                facility: facility,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a batched formulary bundle in status open.
    static func newBatchedFormularyBundle(_ code: String, title: String) -> BatchedFormularyBundle {
        return BatchedFormularyBundle(
            code: code,
            title: title,
            capacity: 0,
            clinicianID: "",
            name: "",
            diagnosisCode: "",
            discount: 0.0,
            facility: "",
            retries: 0,
            status: BatchedFormularyBundleStatus.`open`
        )
    }
}
