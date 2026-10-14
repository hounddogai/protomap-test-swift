import AcmePlatform
import Foundation

extension Labs {
    /// Where a manual courier estimate is in its life cycle.
    enum ManualCourierEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A manual courier estimate. Its code is unique within a tenant.
    final class ManualCourierEstimate {
        var code: String
        var label: String
        var active: Bool
        var budget: Double
        var dosageMg: Double
        var ownerID: String
        var notes: String
        var contactEmail: String
        var margin: Double
        var retries: Int
        var segment: String
        var status: ManualCourierEstimateStatus

        init(code: String, label: String, active: Bool, budget: Double, dosageMg: Double, ownerID: String, notes: String, contactEmail: String, margin: Double, retries: Int, segment: String, status: ManualCourierEstimateStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.budget = budget
            self.dosageMg = dosageMg
            self.ownerID = ownerID
            self.notes = notes
            self.contactEmail = contactEmail
            self.margin = margin
            self.retries = retries
            self.segment = segment
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

        func canMoveTo(_ next: ManualCourierEstimateStatus) -> Bool {
            switch status {
            case .new:
                return next == ManualCourierEstimateStatus.queued || next == ManualCourierEstimateStatus.running
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ManualCourierEstimateStatus.failed
            case .done:
                return next == ManualCourierEstimateStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualCourierEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual courier estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveValue() -> Double {
            return (dosageMg * budget * 100).rounded() / 100
        }

        func copyValue() -> ManualCourierEstimate {
            return ManualCourierEstimate(
                code: code,
                label: label,
                active: active,
                budget: budget,
                dosageMg: dosageMg,
                ownerID: ownerID,
                notes: notes,
                contactEmail: contactEmail,
                margin: margin,
                retries: retries,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a manual courier estimate in status new.
    static func newManualCourierEstimate(_ code: String, label: String) -> ManualCourierEstimate {
        return ManualCourierEstimate(
            code: code,
            label: label,
            active: false,
            budget: 0.0,
            dosageMg: 0.0,
            ownerID: "",
            notes: "",
            contactEmail: "",
            margin: 0.0,
            retries: 0,
            segment: "",
            status: ManualCourierEstimateStatus.new
        )
    }
}
