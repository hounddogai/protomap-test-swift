import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility template is in its life cycle.
    enum EligibilityTemplateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a eligibility template and its current status.
    final class EligibilityTemplate {
        var code: String
        var label: String
        var visitMinutes: Int
        var pinned: Bool
        var floorValue: Double
        var summary: String
        var status: EligibilityTemplateStatus

        init(code: String, label: String, visitMinutes: Int, pinned: Bool, floorValue: Double, summary: String, status: EligibilityTemplateStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.pinned = pinned
            self.floorValue = floorValue
            self.summary = summary
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

        func canMoveTo(_ next: EligibilityTemplateStatus) -> Bool {
            switch status {
            case .new:
                return next == EligibilityTemplateStatus.done
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == EligibilityTemplateStatus.done
            case .done:
                return next == EligibilityTemplateStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netLoad() -> Double {
            return ((floorValue - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityTemplate {
            return EligibilityTemplate(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                pinned: pinned,
                floorValue: floorValue,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a eligibility template in status new.
    static func newEligibilityTemplate(_ code: String, label: String) -> EligibilityTemplate {
        return EligibilityTemplate(
            code: code,
            label: label,
            visitMinutes: 0,
            pinned: false,
            floorValue: 0.0,
            summary: "",
            status: EligibilityTemplateStatus.new
        )
    }
}
