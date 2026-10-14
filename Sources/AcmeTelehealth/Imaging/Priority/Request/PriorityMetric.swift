import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority metric is in its life cycle.
    enum PriorityMetricStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A priority metric as the priority team keeps it.
    final class PriorityMetric {
        var code: String
        var title: String
        var attributes: [String: String]
        var specialty: String
        var rate: Double
        var copay: Double
        var allergy: String
        var status: PriorityMetricStatus

        init(code: String, title: String, attributes: [String: String], specialty: String, rate: Double, copay: Double, allergy: String, status: PriorityMetricStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.specialty = specialty
            self.rate = rate
            self.copay = copay
            self.allergy = allergy
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

        func canMoveTo(_ next: PriorityMetricStatus) -> Bool {
            switch status {
            case .idle:
                return next == PriorityMetricStatus.draining
            case .warming:
                return next == PriorityMetricStatus.ready || next == PriorityMetricStatus.draining
            case .ready:
                return next == PriorityMetricStatus.draining
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

        func moveTo(_ next: PriorityMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("priority metric") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedValue() -> Double {
            return ((rate + copay) * 100).rounded() / 100
        }

        func copyValue() -> PriorityMetric {
            return PriorityMetric(
                code: code,
                title: title,
                attributes: attributes,
                specialty: specialty,
                rate: rate,
                copay: copay,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a priority metric in status idle.
    static func newPriorityMetric(_ code: String, title: String) -> PriorityMetric {
        return PriorityMetric(
            code: code,
            title: title,
            attributes: [:],
            specialty: "",
            rate: 0.0,
            copay: 0.0,
            allergy: "",
            status: PriorityMetricStatus.idle
        )
    }
}
