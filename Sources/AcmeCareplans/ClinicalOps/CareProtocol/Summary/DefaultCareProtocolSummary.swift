import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a default care protocol summary is in its life cycle.
    enum DefaultCareProtocolSummaryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A default care protocol summary as the care protocol team keeps it.
    final class DefaultCareProtocolSummary {
        var code: String
        var name: String
        var allergy: String
        var patientRef: String
        var facility: String
        var amount: Double
        var status: DefaultCareProtocolSummaryStatus

        init(code: String, name: String, allergy: String, patientRef: String, facility: String, amount: Double, status: DefaultCareProtocolSummaryStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.patientRef = patientRef
            self.facility = facility
            self.amount = amount
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

        func canMoveTo(_ next: DefaultCareProtocolSummaryStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == DefaultCareProtocolSummaryStatus.completed
            case .inProgress:
                return next == DefaultCareProtocolSummaryStatus.completed || next == DefaultCareProtocolSummaryStatus.cancelled
            case .completed:
                return next == DefaultCareProtocolSummaryStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultCareProtocolSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default care protocol summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> DefaultCareProtocolSummary {
            return DefaultCareProtocolSummary(
                code: code,
                name: name,
                allergy: allergy,
                patientRef: patientRef,
                facility: facility,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a default care protocol summary in status planned.
    static func newDefaultCareProtocolSummary(_ code: String, name: String) -> DefaultCareProtocolSummary {
        return DefaultCareProtocolSummary(
            code: code,
            name: name,
            allergy: "",
            patientRef: "",
            facility: "",
            amount: 0.0,
            status: DefaultCareProtocolSummaryStatus.planned
        )
    }
}
