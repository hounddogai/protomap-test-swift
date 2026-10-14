import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending assessment preference is in its life cycle.
    enum PendingAssessmentPreferenceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A pending assessment preference. Its code is unique within a tenant.
    final class PendingAssessmentPreference {
        var code: String
        var label: String
        var threshold: Double
        var durationMinutes: Int
        var pinned: Bool
        var ratio: Double
        var channel: String
        var active: Bool
        var status: PendingAssessmentPreferenceStatus

        init(code: String, label: String, threshold: Double, durationMinutes: Int, pinned: Bool, ratio: Double, channel: String, active: Bool, status: PendingAssessmentPreferenceStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.durationMinutes = durationMinutes
            self.pinned = pinned
            self.ratio = ratio
            self.channel = channel
            self.active = active
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

        func canMoveTo(_ next: PendingAssessmentPreferenceStatus) -> Bool {
            switch status {
            case .new:
                return next == PendingAssessmentPreferenceStatus.running
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PendingAssessmentPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending assessment preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("pending assessment preference") \(code)"
        }

        func weightedExposure() -> Double {
            return ((threshold + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> PendingAssessmentPreference {
            return PendingAssessmentPreference(
                code: code,
                label: label,
                threshold: threshold,
                durationMinutes: durationMinutes,
                pinned: pinned,
                ratio: ratio,
                channel: channel,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a pending assessment preference in status new.
    static func newPendingAssessmentPreference(_ code: String, label: String) -> PendingAssessmentPreference {
        return PendingAssessmentPreference(
            code: code,
            label: label,
            threshold: 0.0,
            durationMinutes: 0,
            pinned: false,
            ratio: 0.0,
            channel: "",
            active: false,
            status: PendingAssessmentPreferenceStatus.new
        )
    }
}
