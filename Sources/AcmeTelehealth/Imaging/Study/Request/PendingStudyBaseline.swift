import AcmePlatform
import Foundation

extension Imaging {
    /// Where a pending study baseline is in its life cycle.
    enum PendingStudyBaselineStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A pending study baseline. Its code is unique within a tenant.
    final class PendingStudyBaseline {
        var code: String
        var title: String
        var minimum: Double
        var revision: Int
        var acuity: Int
        var rate: Double
        var ward: String
        var procedureCode: String
        var status: PendingStudyBaselineStatus

        init(code: String, title: String, minimum: Double, revision: Int, acuity: Int, rate: Double, ward: String, procedureCode: String, status: PendingStudyBaselineStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.revision = revision
            self.acuity = acuity
            self.rate = rate
            self.ward = ward
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: PendingStudyBaselineStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PendingStudyBaselineStatus.suspended
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

        func moveTo(_ next: PendingStudyBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending study baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedExposure() -> Double {
            return ((rate + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> PendingStudyBaseline {
            return PendingStudyBaseline(
                code: code,
                title: title,
                minimum: minimum,
                revision: revision,
                acuity: acuity,
                rate: rate,
                ward: ward,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a pending study baseline in status draft.
    static func newPendingStudyBaseline(_ code: String, title: String) -> PendingStudyBaseline {
        return PendingStudyBaseline(
            code: code,
            title: title,
            minimum: 0.0,
            revision: 0,
            acuity: 0,
            rate: 0.0,
            ward: "",
            procedureCode: "",
            status: PendingStudyBaselineStatus.draft
        )
    }
}
