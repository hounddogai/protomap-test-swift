import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy specimen metric is in its life cycle.
    enum LegacySpecimenMetricStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A legacy specimen metric as the specimen team keeps it.
    final class LegacySpecimenMetric {
        var code: String
        var name: String
        var acuity: Int
        var region: String
        var reviewer: String
        var capacity: Int
        var facility: String
        var priority: Int
        var label: String
        var status: LegacySpecimenMetricStatus

        init(code: String, name: String, acuity: Int, region: String, reviewer: String, capacity: Int, facility: String, priority: Int, label: String, status: LegacySpecimenMetricStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.region = region
            self.reviewer = reviewer
            self.capacity = capacity
            self.facility = facility
            self.priority = priority
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

        func canMoveTo(_ next: LegacySpecimenMetricStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == LegacySpecimenMetricStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacySpecimenMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy specimen metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func effectiveTotal() -> Double {
            return ((Double(priority) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> LegacySpecimenMetric {
            return LegacySpecimenMetric(
                code: code,
                name: name,
                acuity: acuity,
                region: region,
                reviewer: reviewer,
                capacity: capacity,
                facility: facility,
                priority: priority,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a legacy specimen metric in status new.
    static func newLegacySpecimenMetric(_ code: String, name: String) -> LegacySpecimenMetric {
        return LegacySpecimenMetric(
            code: code,
            name: name,
            acuity: 0,
            region: "",
            reviewer: "",
            capacity: 0,
            facility: "",
            priority: 0,
            label: "",
            status: LegacySpecimenMetricStatus.new
        )
    }
}
