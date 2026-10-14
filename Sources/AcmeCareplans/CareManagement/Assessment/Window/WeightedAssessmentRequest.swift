import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted assessment request is in its life cycle.
    enum WeightedAssessmentRequestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One weighted assessment request, with what the planners need to act on it.
    final class WeightedAssessmentRequest {
        var code: String
        var title: String
        var specialty: String
        var endsAt: Int
        var capacity: Int
        var rate: Double
        var name: String
        var discount: Double
        var payer: String
        var phone: String
        var status: WeightedAssessmentRequestStatus

        init(code: String, title: String, specialty: String, endsAt: Int, capacity: Int, rate: Double, name: String, discount: Double, payer: String, phone: String, status: WeightedAssessmentRequestStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.endsAt = endsAt
            self.capacity = capacity
            self.rate = rate
            self.name = name
            self.discount = discount
            self.payer = payer
            self.phone = phone
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

        func canMoveTo(_ next: WeightedAssessmentRequestStatus) -> Bool {
            switch status {
            case .new:
                return next == WeightedAssessmentRequestStatus.running || next == WeightedAssessmentRequestStatus.failed
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == WeightedAssessmentRequestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedAssessmentRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted assessment request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("weighted assessment request") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((discount + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedAssessmentRequest {
            return WeightedAssessmentRequest(
                code: code,
                title: title,
                specialty: specialty,
                endsAt: endsAt,
                capacity: capacity,
                rate: rate,
                name: name,
                discount: discount,
                payer: payer,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a weighted assessment request in status new.
    static func newWeightedAssessmentRequest(_ code: String, title: String) -> WeightedAssessmentRequest {
        return WeightedAssessmentRequest(
            code: code,
            title: title,
            specialty: "",
            endsAt: 0,
            capacity: 0,
            rate: 0.0,
            name: "",
            discount: 0.0,
            payer: "",
            phone: "",
            status: WeightedAssessmentRequestStatus.new
        )
    }
}
