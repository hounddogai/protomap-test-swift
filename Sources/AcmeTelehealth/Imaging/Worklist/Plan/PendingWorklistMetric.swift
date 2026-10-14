import AcmePlatform
import Foundation

extension Imaging {
    /// Where a pending worklist metric is in its life cycle.
    enum PendingWorklistMetricStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A pending worklist metric. Its code is unique within a tenant.
    final class PendingWorklistMetric {
        var code: String
        var label: String
        var endsAt: Int
        var batchSize: Int
        var cost: Double
        var durationMinutes: Int
        var limit: Int
        var capacity: Int
        var allergy: String
        var createdAt: Int
        var patientRef: String
        var status: PendingWorklistMetricStatus

        init(code: String, label: String, endsAt: Int, batchSize: Int, cost: Double, durationMinutes: Int, limit: Int, capacity: Int, allergy: String, createdAt: Int, patientRef: String, status: PendingWorklistMetricStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.batchSize = batchSize
            self.cost = cost
            self.durationMinutes = durationMinutes
            self.limit = limit
            self.capacity = capacity
            self.allergy = allergy
            self.createdAt = createdAt
            self.patientRef = patientRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingWorklistMetricStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PendingWorklistMetricStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingWorklistMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending worklist metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedValue() -> Double {
            return ((Double(limit) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> PendingWorklistMetric {
            return PendingWorklistMetric(
                code: code,
                label: label,
                endsAt: endsAt,
                batchSize: batchSize,
                cost: cost,
                durationMinutes: durationMinutes,
                limit: limit,
                capacity: capacity,
                allergy: allergy,
                createdAt: createdAt,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending worklist metric in status proposed.
    static func newPendingWorklistMetric(_ code: String, label: String) -> PendingWorklistMetric {
        return PendingWorklistMetric(
            code: code,
            label: label,
            endsAt: 0,
            batchSize: 0,
            cost: 0.0,
            durationMinutes: 0,
            limit: 0,
            capacity: 0,
            allergy: "",
            createdAt: 0,
            patientRef: "",
            status: PendingWorklistMetricStatus.proposed
        )
    }
}
