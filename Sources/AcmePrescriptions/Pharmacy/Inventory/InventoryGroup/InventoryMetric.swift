import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory metric is in its life cycle.
    enum InventoryMetricStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A inventory metric as the inventory team keeps it.
    final class InventoryMetric {
        var code: String
        var title: String
        var procedureCode: String
        var source: String
        var ratio: Double
        var threshold: Double
        var refills: Int
        var version: Int
        var startsAt: Int
        var status: InventoryMetricStatus

        init(code: String, title: String, procedureCode: String, source: String, ratio: Double, threshold: Double, refills: Int, version: Int, startsAt: Int, status: InventoryMetricStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.source = source
            self.ratio = ratio
            self.threshold = threshold
            self.refills = refills
            self.version = version
            self.startsAt = startsAt
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

        func canMoveTo(_ next: InventoryMetricStatus) -> Bool {
            switch status {
            case .planned:
                return next == InventoryMetricStatus.inProgress
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == InventoryMetricStatus.completed || next == InventoryMetricStatus.cancelled
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

        func moveTo(_ next: InventoryMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveValue() -> Double {
            return ((ratio + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> InventoryMetric {
            return InventoryMetric(
                code: code,
                title: title,
                procedureCode: procedureCode,
                source: source,
                ratio: ratio,
                threshold: threshold,
                refills: refills,
                version: version,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a inventory metric in status planned.
    static func newInventoryMetric(_ code: String, title: String) -> InventoryMetric {
        return InventoryMetric(
            code: code,
            title: title,
            procedureCode: "",
            source: "",
            ratio: 0.0,
            threshold: 0.0,
            refills: 0,
            version: 0,
            startsAt: 0,
            status: InventoryMetricStatus.planned
        )
    }
}
