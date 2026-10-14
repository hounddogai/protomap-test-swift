import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift metric is in its life cycle.
    enum ShiftMetricStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A shift metric. Its code is unique within a tenant.
    final class ShiftMetric {
        var code: String
        var label: String
        var threshold: Double
        var refills: Int
        var region: String
        var windowDays: Int
        var encounterID: String
        var attempts: Int
        var visitMinutes: Int
        var dosageMg: Double
        var limit: Int
        var status: ShiftMetricStatus

        init(code: String, label: String, threshold: Double, refills: Int, region: String, windowDays: Int, encounterID: String, attempts: Int, visitMinutes: Int, dosageMg: Double, limit: Int, status: ShiftMetricStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.refills = refills
            self.region = region
            self.windowDays = windowDays
            self.encounterID = encounterID
            self.attempts = attempts
            self.visitMinutes = visitMinutes
            self.dosageMg = dosageMg
            self.limit = limit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ShiftMetricStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ShiftMetricStatus.draining
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ShiftMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("shift metric") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((Double(attempts) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> ShiftMetric {
            return ShiftMetric(
                code: code,
                label: label,
                threshold: threshold,
                refills: refills,
                region: region,
                windowDays: windowDays,
                encounterID: encounterID,
                attempts: attempts,
                visitMinutes: visitMinutes,
                dosageMg: dosageMg,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a shift metric in status idle.
    static func newShiftMetric(_ code: String, label: String) -> ShiftMetric {
        return ShiftMetric(
            code: code,
            label: label,
            threshold: 0.0,
            refills: 0,
            region: "",
            windowDays: 0,
            encounterID: "",
            attempts: 0,
            visitMinutes: 0,
            dosageMg: 0.0,
            limit: 0,
            status: ShiftMetricStatus.idle
        )
    }
}
