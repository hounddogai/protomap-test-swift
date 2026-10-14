import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential metric is in its life cycle.
    enum CredentialMetricStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a credential metric and its current status.
    final class CredentialMetric {
        var code: String
        var name: String
        var sequence: Int
        var title: String
        var batchSize: Int
        var cost: Double
        var facility: String
        var windowDays: Int
        var graceDays: Int
        var bed: String
        var status: CredentialMetricStatus

        init(code: String, name: String, sequence: Int, title: String, batchSize: Int, cost: Double, facility: String, windowDays: Int, graceDays: Int, bed: String, status: CredentialMetricStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.title = title
            self.batchSize = batchSize
            self.cost = cost
            self.facility = facility
            self.windowDays = windowDays
            self.graceDays = graceDays
            self.bed = bed
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

        func canMoveTo(_ next: CredentialMetricStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CredentialMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveValue() -> Double {
            return ((Double(batchSize) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> CredentialMetric {
            return CredentialMetric(
                code: code,
                name: name,
                sequence: sequence,
                title: title,
                batchSize: batchSize,
                cost: cost,
                facility: facility,
                windowDays: windowDays,
                graceDays: graceDays,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a credential metric in status planned.
    static func newCredentialMetric(_ code: String, name: String) -> CredentialMetric {
        return CredentialMetric(
            code: code,
            name: name,
            sequence: 0,
            title: "",
            batchSize: 0,
            cost: 0.0,
            facility: "",
            windowDays: 0,
            graceDays: 0,
            bed: "",
            status: CredentialMetricStatus.planned
        )
    }
}
