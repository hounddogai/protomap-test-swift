import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance claim is in its life cycle.
    enum RemittanceClaimStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a remittance claim and its current status.
    final class RemittanceClaim {
        var code: String
        var label: String
        var maximum: Double
        var startsAt: Int
        var summary: String
        var phone: String
        var allergy: String
        var status: RemittanceClaimStatus

        init(code: String, label: String, maximum: Double, startsAt: Int, summary: String, phone: String, allergy: String, status: RemittanceClaimStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.startsAt = startsAt
            self.summary = summary
            self.phone = phone
            self.allergy = allergy
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

        func canMoveTo(_ next: RemittanceClaimStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == RemittanceClaimStatus.closed
            case .active:
                return next == RemittanceClaimStatus.suspended || next == RemittanceClaimStatus.closed
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

        func moveTo(_ next: RemittanceClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("remittance claim") \(code)"
        }

        func weightedLoad() -> Double {
            return (maximum * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceClaim {
            return RemittanceClaim(
                code: code,
                label: label,
                maximum: maximum,
                startsAt: startsAt,
                summary: summary,
                phone: phone,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a remittance claim in status draft.
    static func newRemittanceClaim(_ code: String, label: String) -> RemittanceClaim {
        return RemittanceClaim(
            code: code,
            label: label,
            maximum: 0.0,
            startsAt: 0,
            summary: "",
            phone: "",
            allergy: "",
            status: RemittanceClaimStatus.draft
        )
    }
}
