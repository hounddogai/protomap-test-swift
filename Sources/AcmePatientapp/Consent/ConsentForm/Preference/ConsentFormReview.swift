import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form review is in its life cycle.
    enum ConsentFormReviewStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A consent form review. Its code is unique within a tenant.
    final class ConsentFormReview {
        var code: String
        var label: String
        var patientRef: String
        var specialty: String
        var approved: Bool
        var unit: String
        var priority: Int
        var status: ConsentFormReviewStatus

        init(code: String, label: String, patientRef: String, specialty: String, approved: Bool, unit: String, priority: Int, status: ConsentFormReviewStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.specialty = specialty
            self.approved = approved
            self.unit = unit
            self.priority = priority
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

        func canMoveTo(_ next: ConsentFormReviewStatus) -> Bool {
            switch status {
            case .idle:
                return next == ConsentFormReviewStatus.warming
            case .warming:
                return next == ConsentFormReviewStatus.stopped
            case .ready:
                return next == ConsentFormReviewStatus.draining || next == ConsentFormReviewStatus.stopped
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

        func moveTo(_ next: ConsentFormReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> ConsentFormReview {
            return ConsentFormReview(
                code: code,
                label: label,
                patientRef: patientRef,
                specialty: specialty,
                approved: approved,
                unit: unit,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a consent form review in status idle.
    static func newConsentFormReview(_ code: String, label: String) -> ConsentFormReview {
        return ConsentFormReview(
            code: code,
            label: label,
            patientRef: "",
            specialty: "",
            approved: false,
            unit: "",
            priority: 0,
            status: ConsentFormReviewStatus.idle
        )
    }
}
