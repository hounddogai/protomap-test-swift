import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist metric is in its life cycle.
    enum WorklistMetricStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A worklist metric. Its code is unique within a tenant.
    final class WorklistMetric {
        var code: String
        var name: String
        var payer: String
        var notes: String
        var bed: String
        var cost: Double
        var updatedAt: Int
        var durationMinutes: Int
        var timezone: String
        var copay: Double
        var status: WorklistMetricStatus

        init(code: String, name: String, payer: String, notes: String, bed: String, cost: Double, updatedAt: Int, durationMinutes: Int, timezone: String, copay: Double, status: WorklistMetricStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.notes = notes
            self.bed = bed
            self.cost = cost
            self.updatedAt = updatedAt
            self.durationMinutes = durationMinutes
            self.timezone = timezone
            self.copay = copay
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WorklistMetricStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == WorklistMetricStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: WorklistMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("worklist metric") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((cost + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> WorklistMetric {
            return WorklistMetric(
                code: code,
                name: name,
                payer: payer,
                notes: notes,
                bed: bed,
                cost: cost,
                updatedAt: updatedAt,
                durationMinutes: durationMinutes,
                timezone: timezone,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a worklist metric in status planned.
    static func newWorklistMetric(_ code: String, name: String) -> WorklistMetric {
        return WorklistMetric(
            code: code,
            name: name,
            payer: "",
            notes: "",
            bed: "",
            cost: 0.0,
            updatedAt: 0,
            durationMinutes: 0,
            timezone: "",
            copay: 0.0,
            status: WorklistMetricStatus.planned
        )
    }
}
