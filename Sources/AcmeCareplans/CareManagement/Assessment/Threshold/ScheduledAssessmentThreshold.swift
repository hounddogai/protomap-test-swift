import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled assessment threshold is in its life cycle.
    enum ScheduledAssessmentThresholdStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One scheduled assessment threshold, with what the planners need to act on it.
    final class ScheduledAssessmentThreshold {
        var code: String
        var title: String
        var visitMinutes: Int
        var channel: String
        var ceiling: Double
        var facility: String
        var endsAt: Int
        var batchSize: Int
        var source: String
        var status: ScheduledAssessmentThresholdStatus

        init(code: String, title: String, visitMinutes: Int, channel: String, ceiling: Double, facility: String, endsAt: Int, batchSize: Int, source: String, status: ScheduledAssessmentThresholdStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.channel = channel
            self.ceiling = ceiling
            self.facility = facility
            self.endsAt = endsAt
            self.batchSize = batchSize
            self.source = source
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

        func canMoveTo(_ next: ScheduledAssessmentThresholdStatus) -> Bool {
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
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ScheduledAssessmentThresholdStatus.done || next == ScheduledAssessmentThresholdStatus.failed
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

        func moveTo(_ next: ScheduledAssessmentThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled assessment threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("scheduled assessment threshold") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(endsAt) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledAssessmentThreshold {
            return ScheduledAssessmentThreshold(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                channel: channel,
                ceiling: ceiling,
                facility: facility,
                endsAt: endsAt,
                batchSize: batchSize,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a scheduled assessment threshold in status new.
    static func newScheduledAssessmentThreshold(_ code: String, title: String) -> ScheduledAssessmentThreshold {
        return ScheduledAssessmentThreshold(
            code: code,
            title: title,
            visitMinutes: 0,
            channel: "",
            ceiling: 0.0,
            facility: "",
            endsAt: 0,
            batchSize: 0,
            source: "",
            status: ScheduledAssessmentThresholdStatus.new
        )
    }
}
