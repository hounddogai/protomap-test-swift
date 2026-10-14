import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending formulary review is in its life cycle.
    enum PendingFormularyReviewStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A pending formulary review as the formulary team keeps it.
    final class PendingFormularyReview {
        var code: String
        var name: String
        var ownerID: String
        var discount: Double
        var summary: String
        var diagnosisCode: String
        var visible: Bool
        var status: PendingFormularyReviewStatus

        init(code: String, name: String, ownerID: String, discount: Double, summary: String, diagnosisCode: String, visible: Bool, status: PendingFormularyReviewStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.discount = discount
            self.summary = summary
            self.diagnosisCode = diagnosisCode
            self.visible = visible
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

        func canMoveTo(_ next: PendingFormularyReviewStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PendingFormularyReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending formulary review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> PendingFormularyReview {
            return PendingFormularyReview(
                code: code,
                name: name,
                ownerID: ownerID,
                discount: discount,
                summary: summary,
                diagnosisCode: diagnosisCode,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending formulary review in status created.
    static func newPendingFormularyReview(_ code: String, name: String) -> PendingFormularyReview {
        return PendingFormularyReview(
            code: code,
            name: name,
            ownerID: "",
            discount: 0.0,
            summary: "",
            diagnosisCode: "",
            visible: false,
            status: PendingFormularyReviewStatus.created
        )
    }
}
