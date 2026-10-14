import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning template is in its life cycle.
    enum CleaningTemplateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One cleaning template, with what the planners need to act on it.
    final class CleaningTemplate {
        var code: String
        var label: String
        var notes: String
        var capacity: Int
        var currency: String
        var ceiling: Double
        var region: String
        var specialty: String
        var ratio: Double
        var discount: Double
        var clinicianID: String
        var status: CleaningTemplateStatus

        init(code: String, label: String, notes: String, capacity: Int, currency: String, ceiling: Double, region: String, specialty: String, ratio: Double, discount: Double, clinicianID: String, status: CleaningTemplateStatus) {
            self.code = code
            self.label = label
            self.notes = notes
            self.capacity = capacity
            self.currency = currency
            self.ceiling = ceiling
            self.region = region
            self.specialty = specialty
            self.ratio = ratio
            self.discount = discount
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: CleaningTemplateStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == CleaningTemplateStatus.suspended || next == CleaningTemplateStatus.closed
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

        func moveTo(_ next: CleaningTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("cleaning template") \(code)"
        }

        func projectedLoad() -> Double {
            return (ceiling * ratio * 100).rounded() / 100
        }

        func copyValue() -> CleaningTemplate {
            return CleaningTemplate(
                code: code,
                label: label,
                notes: notes,
                capacity: capacity,
                currency: currency,
                ceiling: ceiling,
                region: region,
                specialty: specialty,
                ratio: ratio,
                discount: discount,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a cleaning template in status draft.
    static func newCleaningTemplate(_ code: String, label: String) -> CleaningTemplate {
        return CleaningTemplate(
            code: code,
            label: label,
            notes: "",
            capacity: 0,
            currency: "",
            ceiling: 0.0,
            region: "",
            specialty: "",
            ratio: 0.0,
            discount: 0.0,
            clinicianID: "",
            status: CleaningTemplateStatus.draft
        )
    }
}
