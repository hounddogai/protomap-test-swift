import AcmePlatform
import Foundation

extension Referrals {
    /// Where a primary eligibility claim is in its life cycle.
    enum PrimaryEligibilityClaimStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a primary eligibility claim and its current status.
    final class PrimaryEligibilityClaim {
        var code: String
        var name: String
        var phone: String
        var reviewer: String
        var graceDays: Int
        var minimum: Double
        var clinicianID: String
        var ceiling: Double
        var status: PrimaryEligibilityClaimStatus

        init(code: String, name: String, phone: String, reviewer: String, graceDays: Int, minimum: Double, clinicianID: String, ceiling: Double, status: PrimaryEligibilityClaimStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.reviewer = reviewer
            self.graceDays = graceDays
            self.minimum = minimum
            self.clinicianID = clinicianID
            self.ceiling = ceiling
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

        func canMoveTo(_ next: PrimaryEligibilityClaimStatus) -> Bool {
            switch status {
            case .new:
                return next == PrimaryEligibilityClaimStatus.failed
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
                switch next {
                case .failed:
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

        func moveTo(_ next: PrimaryEligibilityClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary eligibility claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveVolume() -> Double {
            return ((minimum - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryEligibilityClaim {
            return PrimaryEligibilityClaim(
                code: code,
                name: name,
                phone: phone,
                reviewer: reviewer,
                graceDays: graceDays,
                minimum: minimum,
                clinicianID: clinicianID,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary eligibility claim in status new.
    static func newPrimaryEligibilityClaim(_ code: String, name: String) -> PrimaryEligibilityClaim {
        return PrimaryEligibilityClaim(
            code: code,
            name: name,
            phone: "",
            reviewer: "",
            graceDays: 0,
            minimum: 0.0,
            clinicianID: "",
            ceiling: 0.0,
            status: PrimaryEligibilityClaimStatus.new
        )
    }
}
