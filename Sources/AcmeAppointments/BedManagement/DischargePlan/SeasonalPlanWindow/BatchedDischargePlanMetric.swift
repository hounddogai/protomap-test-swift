import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a batched discharge plan metric is in its life cycle.
    enum BatchedDischargePlanMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a batched discharge plan metric and its current status.
    final class BatchedDischargePlanMetric {
        var code: String
        var label: String
        var attempts: Int
        var createdAt: Int
        var floorValue: Double
        var archived: Bool
        var version: Int
        var budget: Double
        var margin: Double
        var tags: [String]
        var active: Bool
        var status: BatchedDischargePlanMetricStatus

        init(code: String, label: String, attempts: Int, createdAt: Int, floorValue: Double, archived: Bool, version: Int, budget: Double, margin: Double, tags: [String], active: Bool, status: BatchedDischargePlanMetricStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.createdAt = createdAt
            self.floorValue = floorValue
            self.archived = archived
            self.version = version
            self.budget = budget
            self.margin = margin
            self.tags = tags
            self.active = active
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedDischargePlanMetricStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == BatchedDischargePlanMetricStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedDischargePlanMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched discharge plan metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("batched discharge plan metric") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveExposure() -> Double {
            return ((Double(version) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedDischargePlanMetric {
            return BatchedDischargePlanMetric(
                code: code,
                label: label,
                attempts: attempts,
                createdAt: createdAt,
                floorValue: floorValue,
                archived: archived,
                version: version,
                budget: budget,
                margin: margin,
                tags: tags,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched discharge plan metric in status requested.
    static func newBatchedDischargePlanMetric(_ code: String, label: String) -> BatchedDischargePlanMetric {
        return BatchedDischargePlanMetric(
            code: code,
            label: label,
            attempts: 0,
            createdAt: 0,
            floorValue: 0.0,
            archived: false,
            version: 0,
            budget: 0.0,
            margin: 0.0,
            tags: [],
            active: false,
            status: BatchedDischargePlanMetricStatus.requested
        )
    }
}
