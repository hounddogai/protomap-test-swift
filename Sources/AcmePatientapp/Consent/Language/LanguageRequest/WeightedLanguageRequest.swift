import AcmePlatform
import Foundation

extension Consent {
    /// Where a weighted language request is in its life cycle.
    enum WeightedLanguageRequestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a weighted language request and its current status.
    final class WeightedLanguageRequest {
        var code: String
        var title: String
        var revision: Int
        var discount: Double
        var specialty: String
        var payer: String
        var bed: String
        var status: WeightedLanguageRequestStatus

        init(code: String, title: String, revision: Int, discount: Double, specialty: String, payer: String, bed: String, status: WeightedLanguageRequestStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.discount = discount
            self.specialty = specialty
            self.payer = payer
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedLanguageRequestStatus) -> Bool {
            switch status {
            case .created:
                return next == WeightedLanguageRequestStatus.published || next == WeightedLanguageRequestStatus.retired
            case .validated:
                return next == WeightedLanguageRequestStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: WeightedLanguageRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted language request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("weighted language request") \(code)"
        }

        func weightedTotal() -> Double {
            return (Double(revision) * discount * 100).rounded() / 100
        }

        func copyValue() -> WeightedLanguageRequest {
            return WeightedLanguageRequest(
                code: code,
                title: title,
                revision: revision,
                discount: discount,
                specialty: specialty,
                payer: payer,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a weighted language request in status created.
    static func newWeightedLanguageRequest(_ code: String, title: String) -> WeightedLanguageRequest {
        return WeightedLanguageRequest(
            code: code,
            title: title,
            revision: 0,
            discount: 0.0,
            specialty: "",
            payer: "",
            bed: "",
            status: WeightedLanguageRequestStatus.created
        )
    }
}
