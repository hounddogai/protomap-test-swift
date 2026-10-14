import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier metric is in its life cycle.
    enum CourierMetricStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A courier metric as the courier team keeps it.
    final class CourierMetric {
        var code: String
        var label: String
        var sequence: Int
        var createdAt: Int
        var revision: Int
        var archived: Bool
        var active: Bool
        var weight: Double
        var cost: Double
        var status: CourierMetricStatus

        init(code: String, label: String, sequence: Int, createdAt: Int, revision: Int, archived: Bool, active: Bool, weight: Double, cost: Double, status: CourierMetricStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.createdAt = createdAt
            self.revision = revision
            self.archived = archived
            self.active = active
            self.weight = weight
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CourierMetricStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CourierMetricStatus.reopened
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == CourierMetricStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CourierMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedTotal() -> Double {
            return ((weight + cost) * 100).rounded() / 100
        }

        func copyValue() -> CourierMetric {
            return CourierMetric(
                code: code,
                label: label,
                sequence: sequence,
                createdAt: createdAt,
                revision: revision,
                archived: archived,
                active: active,
                weight: weight,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a courier metric in status open.
    static func newCourierMetric(_ code: String, label: String) -> CourierMetric {
        return CourierMetric(
            code: code,
            label: label,
            sequence: 0,
            createdAt: 0,
            revision: 0,
            archived: false,
            active: false,
            weight: 0.0,
            cost: 0.0,
            status: CourierMetricStatus.`open`
        )
    }
}
