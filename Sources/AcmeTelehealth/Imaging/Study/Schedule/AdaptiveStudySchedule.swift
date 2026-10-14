import AcmePlatform
import Foundation

extension Imaging {
    /// Where a adaptive study schedule is in its life cycle.
    enum AdaptiveStudyScheduleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A adaptive study schedule. Its code is unique within a tenant.
    final class AdaptiveStudySchedule {
        var code: String
        var name: String
        var pinned: Bool
        var summary: String
        var graceDays: Int
        var allergy: String
        var batchSize: Int
        var label: String
        var status: AdaptiveStudyScheduleStatus

        init(code: String, name: String, pinned: Bool, summary: String, graceDays: Int, allergy: String, batchSize: Int, label: String, status: AdaptiveStudyScheduleStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.summary = summary
            self.graceDays = graceDays
            self.allergy = allergy
            self.batchSize = batchSize
            self.label = label
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

        func canMoveTo(_ next: AdaptiveStudyScheduleStatus) -> Bool {
            switch status {
            case .new:
                return next == AdaptiveStudyScheduleStatus.running || next == AdaptiveStudyScheduleStatus.done
            case .queued:
                return next == AdaptiveStudyScheduleStatus.failed
            case .running:
                return next == AdaptiveStudyScheduleStatus.done || next == AdaptiveStudyScheduleStatus.failed
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

        func moveTo(_ next: AdaptiveStudyScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive study schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("adaptive study schedule") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(batchSize) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveStudySchedule {
            return AdaptiveStudySchedule(
                code: code,
                name: name,
                pinned: pinned,
                summary: summary,
                graceDays: graceDays,
                allergy: allergy,
                batchSize: batchSize,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive study schedule in status new.
    static func newAdaptiveStudySchedule(_ code: String, name: String) -> AdaptiveStudySchedule {
        return AdaptiveStudySchedule(
            code: code,
            name: name,
            pinned: false,
            summary: "",
            graceDays: 0,
            allergy: "",
            batchSize: 0,
            label: "",
            status: AdaptiveStudyScheduleStatus.new
        )
    }
}
