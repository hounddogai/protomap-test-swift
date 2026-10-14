import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense metric is in its life cycle.
    enum DispenseMetricStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A dispense metric. Its code is unique within a tenant.
    final class DispenseMetric {
        var code: String
        var title: String
        var discount: Double
        var phone: String
        var notes: String
        var version: Int
        var status: DispenseMetricStatus

        init(code: String, title: String, discount: Double, phone: String, notes: String, version: Int, status: DispenseMetricStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.phone = phone
            self.notes = notes
            self.version = version
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

        func canMoveTo(_ next: DispenseMetricStatus) -> Bool {
            switch status {
            case .new:
                return next == DispenseMetricStatus.queued || next == DispenseMetricStatus.failed
            case .queued:
                return next == DispenseMetricStatus.done || next == DispenseMetricStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == DispenseMetricStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispenseMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedVolume() -> Double {
            return (Double(version) * discount * 100).rounded() / 100
        }

        func copyValue() -> DispenseMetric {
            return DispenseMetric(
                code: code,
                title: title,
                discount: discount,
                phone: phone,
                notes: notes,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a dispense metric in status new.
    static func newDispenseMetric(_ code: String, title: String) -> DispenseMetric {
        return DispenseMetric(
            code: code,
            title: title,
            discount: 0.0,
            phone: "",
            notes: "",
            version: 0,
            status: DispenseMetricStatus.new
        )
    }
}
