import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a rolling substitution digest is in its life cycle.
    enum RollingSubstitutionDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a rolling substitution digest and its current status.
    final class RollingSubstitutionDigest {
        var code: String
        var label: String
        var timezone: String
        var ward: String
        var pinned: Bool
        var visible: Bool
        var payer: String
        var amount: Double
        var status: RollingSubstitutionDigestStatus

        init(code: String, label: String, timezone: String, ward: String, pinned: Bool, visible: Bool, payer: String, amount: Double, status: RollingSubstitutionDigestStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.ward = ward
            self.pinned = pinned
            self.visible = visible
            self.payer = payer
            self.amount = amount
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

        func canMoveTo(_ next: RollingSubstitutionDigestStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingSubstitutionDigestStatus.queued
            case .queued:
                return next == RollingSubstitutionDigestStatus.running || next == RollingSubstitutionDigestStatus.failed
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

        func moveTo(_ next: RollingSubstitutionDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling substitution digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> RollingSubstitutionDigest {
            return RollingSubstitutionDigest(
                code: code,
                label: label,
                timezone: timezone,
                ward: ward,
                pinned: pinned,
                visible: visible,
                payer: payer,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a rolling substitution digest in status new.
    static func newRollingSubstitutionDigest(_ code: String, label: String) -> RollingSubstitutionDigest {
        return RollingSubstitutionDigest(
            code: code,
            label: label,
            timezone: "",
            ward: "",
            pinned: false,
            visible: false,
            payer: "",
            amount: 0.0,
            status: RollingSubstitutionDigestStatus.new
        )
    }
}
