import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a legacy goal segment is in its life cycle.
    enum LegacyGoalSegmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One legacy goal segment, with what the planners need to act on it.
    final class LegacyGoalSegment {
        var code: String
        var label: String
        var threshold: Double
        var cost: Double
        var unit: String
        var pinned: Bool
        var capacity: Int
        var diagnosisCode: String
        var windowDays: Int
        var status: LegacyGoalSegmentStatus

        init(code: String, label: String, threshold: Double, cost: Double, unit: String, pinned: Bool, capacity: Int, diagnosisCode: String, windowDays: Int, status: LegacyGoalSegmentStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.cost = cost
            self.unit = unit
            self.pinned = pinned
            self.capacity = capacity
            self.diagnosisCode = diagnosisCode
            self.windowDays = windowDays
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

        func canMoveTo(_ next: LegacyGoalSegmentStatus) -> Bool {
            switch status {
            case .new:
                return next == LegacyGoalSegmentStatus.failed
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == LegacyGoalSegmentStatus.done || next == LegacyGoalSegmentStatus.failed
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

        func moveTo(_ next: LegacyGoalSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy goal segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedVolume() -> Double {
            return ((cost + threshold) * 100).rounded() / 100
        }

        func copyValue() -> LegacyGoalSegment {
            return LegacyGoalSegment(
                code: code,
                label: label,
                threshold: threshold,
                cost: cost,
                unit: unit,
                pinned: pinned,
                capacity: capacity,
                diagnosisCode: diagnosisCode,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a legacy goal segment in status new.
    static func newLegacyGoalSegment(_ code: String, label: String) -> LegacyGoalSegment {
        return LegacyGoalSegment(
            code: code,
            label: label,
            threshold: 0.0,
            cost: 0.0,
            unit: "",
            pinned: false,
            capacity: 0,
            diagnosisCode: "",
            windowDays: 0,
            status: LegacyGoalSegmentStatus.new
        )
    }
}
