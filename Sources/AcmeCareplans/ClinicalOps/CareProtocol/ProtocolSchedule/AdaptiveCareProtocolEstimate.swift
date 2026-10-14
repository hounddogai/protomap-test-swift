import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a adaptive care protocol estimate is in its life cycle.
    enum AdaptiveCareProtocolEstimateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One adaptive care protocol estimate, with what the planners need to act on it.
    final class AdaptiveCareProtocolEstimate {
        var code: String
        var name: String
        var patientRef: String
        var bed: String
        var summary: String
        var acuity: Int
        var status: AdaptiveCareProtocolEstimateStatus

        init(code: String, name: String, patientRef: String, bed: String, summary: String, acuity: Int, status: AdaptiveCareProtocolEstimateStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.bed = bed
            self.summary = summary
            self.acuity = acuity
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

        func canMoveTo(_ next: AdaptiveCareProtocolEstimateStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == AdaptiveCareProtocolEstimateStatus.resolved
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: AdaptiveCareProtocolEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive care protocol estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive care protocol estimate") \(code)"
        }

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> AdaptiveCareProtocolEstimate {
            return AdaptiveCareProtocolEstimate(
                code: code,
                name: name,
                patientRef: patientRef,
                bed: bed,
                summary: summary,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive care protocol estimate in status open.
    static func newAdaptiveCareProtocolEstimate(_ code: String, name: String) -> AdaptiveCareProtocolEstimate {
        return AdaptiveCareProtocolEstimate(
            code: code,
            name: name,
            patientRef: "",
            bed: "",
            summary: "",
            acuity: 0,
            status: AdaptiveCareProtocolEstimateStatus.`open`
        )
    }
}
