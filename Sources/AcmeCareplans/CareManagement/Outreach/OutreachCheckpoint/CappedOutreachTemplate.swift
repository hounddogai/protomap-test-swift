import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a capped outreach template is in its life cycle.
    enum CappedOutreachTemplateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One capped outreach template, with what the planners need to act on it.
    final class CappedOutreachTemplate {
        var code: String
        var label: String
        var amount: Double
        var priority: Int
        var pinned: Bool
        var limit: Int
        var source: String
        var patientRef: String
        var visitMinutes: Int
        var ratio: Double
        var status: CappedOutreachTemplateStatus

        init(code: String, label: String, amount: Double, priority: Int, pinned: Bool, limit: Int, source: String, patientRef: String, visitMinutes: Int, ratio: Double, status: CappedOutreachTemplateStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.priority = priority
            self.pinned = pinned
            self.limit = limit
            self.source = source
            self.patientRef = patientRef
            self.visitMinutes = visitMinutes
            self.ratio = ratio
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

        func canMoveTo(_ next: CappedOutreachTemplateStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == CappedOutreachTemplateStatus.failed
            case .running:
                switch next {
                case .done:
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

        func moveTo(_ next: CappedOutreachTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped outreach template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("capped outreach template") \(code)"
        }

        func projectedLoad() -> Double {
            return (Double(visitMinutes) * amount * 100).rounded() / 100
        }

        func copyValue() -> CappedOutreachTemplate {
            return CappedOutreachTemplate(
                code: code,
                label: label,
                amount: amount,
                priority: priority,
                pinned: pinned,
                limit: limit,
                source: source,
                patientRef: patientRef,
                visitMinutes: visitMinutes,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a capped outreach template in status new.
    static func newCappedOutreachTemplate(_ code: String, label: String) -> CappedOutreachTemplate {
        return CappedOutreachTemplate(
            code: code,
            label: label,
            amount: 0.0,
            priority: 0,
            pinned: false,
            limit: 0,
            source: "",
            patientRef: "",
            visitMinutes: 0,
            ratio: 0.0,
            status: CappedOutreachTemplateStatus.new
        )
    }
}
