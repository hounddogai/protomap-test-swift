import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff baseline is in its life cycle.
    enum HandoffBaselineStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A handoff baseline. Its code is unique within a tenant.
    final class HandoffBaseline {
        var code: String
        var title: String
        var diagnosisCode: String
        var bed: String
        var rate: Double
        var phone: String
        var status: HandoffBaselineStatus

        init(code: String, title: String, diagnosisCode: String, bed: String, rate: Double, phone: String, status: HandoffBaselineStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.bed = bed
            self.rate = rate
            self.phone = phone
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

        func canMoveTo(_ next: HandoffBaselineStatus) -> Bool {
            switch status {
            case .proposed:
                return next == HandoffBaselineStatus.approved || next == HandoffBaselineStatus.withdrawn
            case .approved:
                return next == HandoffBaselineStatus.rejected || next == HandoffBaselineStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: HandoffBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("handoff baseline") \(code)"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> HandoffBaseline {
            return HandoffBaseline(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                bed: bed,
                rate: rate,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a handoff baseline in status proposed.
    static func newHandoffBaseline(_ code: String, title: String) -> HandoffBaseline {
        return HandoffBaseline(
            code: code,
            title: title,
            diagnosisCode: "",
            bed: "",
            rate: 0.0,
            phone: "",
            status: HandoffBaselineStatus.proposed
        )
    }
}
