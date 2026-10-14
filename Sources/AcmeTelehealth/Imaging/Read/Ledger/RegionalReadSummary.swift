import AcmePlatform
import Foundation

extension Imaging {
    /// Where a regional read summary is in its life cycle.
    enum RegionalReadSummaryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A regional read summary as the read team keeps it.
    final class RegionalReadSummary {
        var code: String
        var label: String
        var priority: Int
        var version: Int
        var phone: String
        var patientRef: String
        var specialty: String
        var status: RegionalReadSummaryStatus

        init(code: String, label: String, priority: Int, version: Int, phone: String, patientRef: String, specialty: String, status: RegionalReadSummaryStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.version = version
            self.phone = phone
            self.patientRef = patientRef
            self.specialty = specialty
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalReadSummaryStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == RegionalReadSummaryStatus.closed
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: RegionalReadSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional read summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netTotal() -> Double {
            return ((Double(version) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalReadSummary {
            return RegionalReadSummary(
                code: code,
                label: label,
                priority: priority,
                version: version,
                phone: phone,
                patientRef: patientRef,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional read summary in status draft.
    static func newRegionalReadSummary(_ code: String, label: String) -> RegionalReadSummary {
        return RegionalReadSummary(
            code: code,
            label: label,
            priority: 0,
            version: 0,
            phone: "",
            patientRef: "",
            specialty: "",
            status: RegionalReadSummaryStatus.draft
        )
    }
}
