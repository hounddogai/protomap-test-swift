import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a global dispense metric is in its life cycle.
    enum GlobalDispenseMetricStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A global dispense metric as the dispense team keeps it.
    final class GlobalDispenseMetric {
        var code: String
        var name: String
        var checksum: String
        var tags: [String]
        var diagnosisCode: String
        var title: String
        var ratio: Double
        var graceDays: Int
        var notes: String
        var status: GlobalDispenseMetricStatus

        init(code: String, name: String, checksum: String, tags: [String], diagnosisCode: String, title: String, ratio: Double, graceDays: Int, notes: String, status: GlobalDispenseMetricStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.tags = tags
            self.diagnosisCode = diagnosisCode
            self.title = title
            self.ratio = ratio
            self.graceDays = graceDays
            self.notes = notes
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

        func canMoveTo(_ next: GlobalDispenseMetricStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == GlobalDispenseMetricStatus.ready || next == GlobalDispenseMetricStatus.draining
            case .ready:
                return next == GlobalDispenseMetricStatus.draining
            case .draining:
                return next == GlobalDispenseMetricStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalDispenseMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global dispense metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netExposure() -> Double {
            return ((ratio - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalDispenseMetric {
            return GlobalDispenseMetric(
                code: code,
                name: name,
                checksum: checksum,
                tags: tags,
                diagnosisCode: diagnosisCode,
                title: title,
                ratio: ratio,
                graceDays: graceDays,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global dispense metric in status idle.
    static func newGlobalDispenseMetric(_ code: String, name: String) -> GlobalDispenseMetric {
        return GlobalDispenseMetric(
            code: code,
            name: name,
            checksum: "",
            tags: [],
            diagnosisCode: "",
            title: "",
            ratio: 0.0,
            graceDays: 0,
            notes: "",
            status: GlobalDispenseMetricStatus.idle
        )
    }
}
