import AcmePlatform
import Foundation

extension Referrals {
    /// Where a lenient follow up mapping is in its life cycle.
    enum LenientFollowUpMappingStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a lenient follow up mapping and its current status.
    final class LenientFollowUpMapping {
        var code: String
        var label: String
        var windowDays: Int
        var diagnosisCode: String
        var ratio: Double
        var status: LenientFollowUpMappingStatus

        init(code: String, label: String, windowDays: Int, diagnosisCode: String, ratio: Double, status: LenientFollowUpMappingStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.diagnosisCode = diagnosisCode
            self.ratio = ratio
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

        func canMoveTo(_ next: LenientFollowUpMappingStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == LenientFollowUpMappingStatus.archived
            case .reopened:
                return next == LenientFollowUpMappingStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientFollowUpMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient follow up mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveExposure() -> Double {
            return ((Double(windowDays) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> LenientFollowUpMapping {
            return LenientFollowUpMapping(
                code: code,
                label: label,
                windowDays: windowDays,
                diagnosisCode: diagnosisCode,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient follow up mapping in status open.
    static func newLenientFollowUpMapping(_ code: String, label: String) -> LenientFollowUpMapping {
        return LenientFollowUpMapping(
            code: code,
            label: label,
            windowDays: 0,
            diagnosisCode: "",
            ratio: 0.0,
            status: LenientFollowUpMappingStatus.`open`
        )
    }
}
