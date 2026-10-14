import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach summary is in its life cycle.
    enum OutreachSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One outreach summary, with what the planners need to act on it.
    final class OutreachSummary {
        var code: String
        var title: String
        var specialty: String
        var externalRef: String
        var clinicianID: String
        var allergy: String
        var unit: String
        var bed: String
        var capacity: Int
        var status: OutreachSummaryStatus

        init(code: String, title: String, specialty: String, externalRef: String, clinicianID: String, allergy: String, unit: String, bed: String, capacity: Int, status: OutreachSummaryStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.externalRef = externalRef
            self.clinicianID = clinicianID
            self.allergy = allergy
            self.unit = unit
            self.bed = bed
            self.capacity = capacity
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

        func canMoveTo(_ next: OutreachSummaryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == OutreachSummaryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OutreachSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(capacity)
        }

        func copyValue() -> OutreachSummary {
            return OutreachSummary(
                code: code,
                title: title,
                specialty: specialty,
                externalRef: externalRef,
                clinicianID: clinicianID,
                allergy: allergy,
                unit: unit,
                bed: bed,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a outreach summary in status new.
    static func newOutreachSummary(_ code: String, title: String) -> OutreachSummary {
        return OutreachSummary(
            code: code,
            title: title,
            specialty: "",
            externalRef: "",
            clinicianID: "",
            allergy: "",
            unit: "",
            bed: "",
            capacity: 0,
            status: OutreachSummaryStatus.new
        )
    }
}
