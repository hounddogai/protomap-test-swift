import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial draft is in its life cycle.
    enum DenialDraftStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a denial draft and its current status.
    final class DenialDraft {
        var code: String
        var label: String
        var ratio: Double
        var graceDays: Int
        var margin: Double
        var segment: String
        var visitMinutes: Int
        var status: DenialDraftStatus

        init(code: String, label: String, ratio: Double, graceDays: Int, margin: Double, segment: String, visitMinutes: Int, status: DenialDraftStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.graceDays = graceDays
            self.margin = margin
            self.segment = segment
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

        func canMoveTo(_ next: DenialDraftStatus) -> Bool {
            switch status {
            case .new:
                return next == DenialDraftStatus.failed
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == DenialDraftStatus.done || next == DenialDraftStatus.failed
            case .done:
                return next == DenialDraftStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DenialDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netLoad() -> Double {
            return (ratio * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> DenialDraft {
            return DenialDraft(
                code: code,
                label: label,
                ratio: ratio,
                graceDays: graceDays,
                margin: margin,
                segment: segment,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a denial draft in status new.
    static func newDenialDraft(_ code: String, label: String) -> DenialDraft {
        return DenialDraft(
            code: code,
            label: label,
            ratio: 0.0,
            graceDays: 0,
            margin: 0.0,
            segment: "",
            visitMinutes: 0,
            status: DenialDraftStatus.new
        )
    }
}
