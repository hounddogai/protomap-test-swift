import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool batch is in its life cycle.
    enum FloatPoolBatchStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A float pool batch as the float pool team keeps it.
    final class FloatPoolBatch {
        var code: String
        var title: String
        var facility: String
        var phone: String
        var patientRef: String
        var graceDays: Int
        var status: FloatPoolBatchStatus

        init(code: String, title: String, facility: String, phone: String, patientRef: String, graceDays: Int, status: FloatPoolBatchStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.phone = phone
            self.patientRef = patientRef
            self.graceDays = graceDays
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

        func canMoveTo(_ next: FloatPoolBatchStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == FloatPoolBatchStatus.suspended || next == FloatPoolBatchStatus.closed
            case .suspended:
                return next == FloatPoolBatchStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FloatPoolBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("float pool batch") \(code)"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> FloatPoolBatch {
            return FloatPoolBatch(
                code: code,
                title: title,
                facility: facility,
                phone: phone,
                patientRef: patientRef,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a float pool batch in status draft.
    static func newFloatPoolBatch(_ code: String, title: String) -> FloatPoolBatch {
        return FloatPoolBatch(
            code: code,
            title: title,
            facility: "",
            phone: "",
            patientRef: "",
            graceDays: 0,
            status: FloatPoolBatchStatus.draft
        )
    }
}
