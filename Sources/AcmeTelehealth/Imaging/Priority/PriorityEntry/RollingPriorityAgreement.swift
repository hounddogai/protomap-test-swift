import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling priority agreement is in its life cycle.
    enum RollingPriorityAgreementStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A rolling priority agreement. Its code is unique within a tenant.
    final class RollingPriorityAgreement {
        var code: String
        var title: String
        var procedureCode: String
        var acuity: Int
        var visitMinutes: Int
        var status: RollingPriorityAgreementStatus

        init(code: String, title: String, procedureCode: String, acuity: Int, visitMinutes: Int, status: RollingPriorityAgreementStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.acuity = acuity
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingPriorityAgreementStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingPriorityAgreementStatus.running
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: RollingPriorityAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling priority agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveVolume() -> Double {
            return (Double(acuity) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> RollingPriorityAgreement {
            return RollingPriorityAgreement(
                code: code,
                title: title,
                procedureCode: procedureCode,
                acuity: acuity,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling priority agreement in status new.
    static func newRollingPriorityAgreement(_ code: String, title: String) -> RollingPriorityAgreement {
        return RollingPriorityAgreement(
            code: code,
            title: title,
            procedureCode: "",
            acuity: 0,
            visitMinutes: 0,
            status: RollingPriorityAgreementStatus.new
        )
    }
}
