import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global alert summary is in its life cycle.
    enum GlobalAlertSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a global alert summary and its current status.
    final class GlobalAlertSummary {
        var code: String
        var name: String
        var description: String
        var contactEmail: String
        var segment: String
        var dosageMg: Double
        var status: GlobalAlertSummaryStatus

        init(code: String, name: String, description: String, contactEmail: String, segment: String, dosageMg: Double, status: GlobalAlertSummaryStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.contactEmail = contactEmail
            self.segment = segment
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: GlobalAlertSummaryStatus) -> Bool {
            switch status {
            case .new:
                return next == GlobalAlertSummaryStatus.running
            case .queued:
                return next == GlobalAlertSummaryStatus.done || next == GlobalAlertSummaryStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: GlobalAlertSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global alert summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> GlobalAlertSummary {
            return GlobalAlertSummary(
                code: code,
                name: name,
                description: description,
                contactEmail: contactEmail,
                segment: segment,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a global alert summary in status new.
    static func newGlobalAlertSummary(_ code: String, name: String) -> GlobalAlertSummary {
        return GlobalAlertSummary(
            code: code,
            name: name,
            description: "",
            contactEmail: "",
            segment: "",
            dosageMg: 0.0,
            status: GlobalAlertSummaryStatus.new
        )
    }
}
