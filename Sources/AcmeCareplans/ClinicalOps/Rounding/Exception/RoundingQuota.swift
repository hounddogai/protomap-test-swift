import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding quota is in its life cycle.
    enum RoundingQuotaStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a rounding quota and its current status.
    final class RoundingQuota {
        var code: String
        var title: String
        var pinned: Bool
        var label: String
        var refills: Int
        var revision: Int
        var facility: String
        var attempts: Int
        var quantity: Int
        var payer: String
        var maximum: Double
        var status: RoundingQuotaStatus

        init(code: String, title: String, pinned: Bool, label: String, refills: Int, revision: Int, facility: String, attempts: Int, quantity: Int, payer: String, maximum: Double, status: RoundingQuotaStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.label = label
            self.refills = refills
            self.revision = revision
            self.facility = facility
            self.attempts = attempts
            self.quantity = quantity
            self.payer = payer
            self.maximum = maximum
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

        func canMoveTo(_ next: RoundingQuotaStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == RoundingQuotaStatus.stopped
            case .draining:
                return next == RoundingQuotaStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RoundingQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func adjustedExposure() -> Double {
            return (Double(refills) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> RoundingQuota {
            return RoundingQuota(
                code: code,
                title: title,
                pinned: pinned,
                label: label,
                refills: refills,
                revision: revision,
                facility: facility,
                attempts: attempts,
                quantity: quantity,
                payer: payer,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a rounding quota in status idle.
    static func newRoundingQuota(_ code: String, title: String) -> RoundingQuota {
        return RoundingQuota(
            code: code,
            title: title,
            pinned: false,
            label: "",
            refills: 0,
            revision: 0,
            facility: "",
            attempts: 0,
            quantity: 0,
            payer: "",
            maximum: 0.0,
            status: RoundingQuotaStatus.idle
        )
    }
}
