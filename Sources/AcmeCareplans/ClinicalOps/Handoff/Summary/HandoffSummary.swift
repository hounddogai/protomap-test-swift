import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff summary is in its life cycle.
    enum HandoffSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a handoff summary and its current status.
    final class HandoffSummary {
        var code: String
        var title: String
        var minimum: Double
        var summary: String
        var updatedAt: Int
        var endsAt: Int
        var patientRef: String
        var visible: Bool
        var status: HandoffSummaryStatus

        init(code: String, title: String, minimum: Double, summary: String, updatedAt: Int, endsAt: Int, patientRef: String, visible: Bool, status: HandoffSummaryStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.summary = summary
            self.updatedAt = updatedAt
            self.endsAt = endsAt
            self.patientRef = patientRef
            self.visible = visible
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

        func canMoveTo(_ next: HandoffSummaryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == HandoffSummaryStatus.failed
            case .running:
                return next == HandoffSummaryStatus.done || next == HandoffSummaryStatus.failed
            case .done:
                return next == HandoffSummaryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: HandoffSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedValue() -> Double {
            return (Double(endsAt) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> HandoffSummary {
            return HandoffSummary(
                code: code,
                title: title,
                minimum: minimum,
                summary: summary,
                updatedAt: updatedAt,
                endsAt: endsAt,
                patientRef: patientRef,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a handoff summary in status new.
    static func newHandoffSummary(_ code: String, title: String) -> HandoffSummary {
        return HandoffSummary(
            code: code,
            title: title,
            minimum: 0.0,
            summary: "",
            updatedAt: 0,
            endsAt: 0,
            patientRef: "",
            visible: false,
            status: HandoffSummaryStatus.new
        )
    }
}
