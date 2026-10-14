import AcmePlatform
import Foundation

extension Labs {
    /// Where a lenient courier request is in its life cycle.
    enum LenientCourierRequestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a lenient courier request and its current status.
    final class LenientCourierRequest {
        var code: String
        var label: String
        var sequence: Int
        var segment: String
        var bed: String
        var score: Double
        var weight: Double
        var discount: Double
        var graceDays: Int
        var active: Bool
        var contactEmail: String
        var status: LenientCourierRequestStatus

        init(code: String, label: String, sequence: Int, segment: String, bed: String, score: Double, weight: Double, discount: Double, graceDays: Int, active: Bool, contactEmail: String, status: LenientCourierRequestStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.segment = segment
            self.bed = bed
            self.score = score
            self.weight = weight
            self.discount = discount
            self.graceDays = graceDays
            self.active = active
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientCourierRequestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LenientCourierRequestStatus.resolved || next == LenientCourierRequestStatus.reopened
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: LenientCourierRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient courier request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedValue() -> Double {
            return ((Double(sequence) - discount) * 100).rounded() / 100
        }

        func copyValue() -> LenientCourierRequest {
            return LenientCourierRequest(
                code: code,
                label: label,
                sequence: sequence,
                segment: segment,
                bed: bed,
                score: score,
                weight: weight,
                discount: discount,
                graceDays: graceDays,
                active: active,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a lenient courier request in status open.
    static func newLenientCourierRequest(_ code: String, label: String) -> LenientCourierRequest {
        return LenientCourierRequest(
            code: code,
            label: label,
            sequence: 0,
            segment: "",
            bed: "",
            score: 0.0,
            weight: 0.0,
            discount: 0.0,
            graceDays: 0,
            active: false,
            contactEmail: "",
            status: LenientCourierRequestStatus.`open`
        )
    }
}
