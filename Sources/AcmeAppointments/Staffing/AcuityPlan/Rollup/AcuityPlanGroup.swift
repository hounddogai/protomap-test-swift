import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan group is in its life cycle.
    enum AcuityPlanGroupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a acuity plan group and its current status.
    final class AcuityPlanGroup {
        var code: String
        var label: String
        var startsAt: Int
        var durationMinutes: Int
        var windowDays: Int
        var status: AcuityPlanGroupStatus

        init(code: String, label: String, startsAt: Int, durationMinutes: Int, windowDays: Int, status: AcuityPlanGroupStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: AcuityPlanGroupStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == AcuityPlanGroupStatus.running || next == AcuityPlanGroupStatus.failed
            case .running:
                return next == AcuityPlanGroupStatus.done || next == AcuityPlanGroupStatus.failed
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

        func moveTo(_ next: AcuityPlanGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedExposure() -> Double {
            return (Double(startsAt) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanGroup {
            return AcuityPlanGroup(
                code: code,
                label: label,
                startsAt: startsAt,
                durationMinutes: durationMinutes,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a acuity plan group in status new.
    static func newAcuityPlanGroup(_ code: String, label: String) -> AcuityPlanGroup {
        return AcuityPlanGroup(
            code: code,
            label: label,
            startsAt: 0,
            durationMinutes: 0,
            windowDays: 0,
            status: AcuityPlanGroupStatus.new
        )
    }
}
