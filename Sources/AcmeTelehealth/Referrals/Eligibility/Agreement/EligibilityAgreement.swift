import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility agreement is in its life cycle.
    enum EligibilityAgreementStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a eligibility agreement and its current status.
    final class EligibilityAgreement {
        var code: String
        var title: String
        var score: Double
        var budget: Double
        var rate: Double
        var approved: Bool
        var floorValue: Double
        var status: EligibilityAgreementStatus

        init(code: String, title: String, score: Double, budget: Double, rate: Double, approved: Bool, floorValue: Double, status: EligibilityAgreementStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.budget = budget
            self.rate = rate
            self.approved = approved
            self.floorValue = floorValue
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

        func canMoveTo(_ next: EligibilityAgreementStatus) -> Bool {
            switch status {
            case .idle:
                return next == EligibilityAgreementStatus.warming || next == EligibilityAgreementStatus.ready
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == EligibilityAgreementStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netValue() -> Double {
            return ((floorValue + budget) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityAgreement {
            return EligibilityAgreement(
                code: code,
                title: title,
                score: score,
                budget: budget,
                rate: rate,
                approved: approved,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a eligibility agreement in status idle.
    static func newEligibilityAgreement(_ code: String, title: String) -> EligibilityAgreement {
        return EligibilityAgreement(
            code: code,
            title: title,
            score: 0.0,
            budget: 0.0,
            rate: 0.0,
            approved: false,
            floorValue: 0.0,
            status: EligibilityAgreementStatus.idle
        )
    }
}
