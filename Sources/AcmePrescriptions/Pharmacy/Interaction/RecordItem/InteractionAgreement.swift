import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction agreement is in its life cycle.
    enum InteractionAgreementStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One interaction agreement, with what the planners need to act on it.
    final class InteractionAgreement {
        var code: String
        var label: String
        var source: String
        var clinicianID: String
        var locale: String
        var score: Double
        var ward: String
        var quantity: Int
        var attempts: Int
        var status: InteractionAgreementStatus

        init(code: String, label: String, source: String, clinicianID: String, locale: String, score: Double, ward: String, quantity: Int, attempts: Int, status: InteractionAgreementStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.clinicianID = clinicianID
            self.locale = locale
            self.score = score
            self.ward = ward
            self.quantity = quantity
            self.attempts = attempts
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

        func canMoveTo(_ next: InteractionAgreementStatus) -> Bool {
            switch status {
            case .`open`:
                return next == InteractionAgreementStatus.inReview || next == InteractionAgreementStatus.resolved
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
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == InteractionAgreementStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InteractionAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netLoad() -> Double {
            return ((Double(attempts) + score) * 100).rounded() / 100
        }

        func copyValue() -> InteractionAgreement {
            return InteractionAgreement(
                code: code,
                label: label,
                source: source,
                clinicianID: clinicianID,
                locale: locale,
                score: score,
                ward: ward,
                quantity: quantity,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a interaction agreement in status open.
    static func newInteractionAgreement(_ code: String, label: String) -> InteractionAgreement {
        return InteractionAgreement(
            code: code,
            label: label,
            source: "",
            clinicianID: "",
            locale: "",
            score: 0.0,
            ward: "",
            quantity: 0,
            attempts: 0,
            status: InteractionAgreementStatus.`open`
        )
    }
}
