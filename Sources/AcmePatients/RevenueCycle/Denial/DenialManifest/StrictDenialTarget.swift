import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a strict denial target is in its life cycle.
    enum StrictDenialTargetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One strict denial target, with what the planners need to act on it.
    final class StrictDenialTarget {
        var code: String
        var label: String
        var active: Bool
        var locale: String
        var ownerID: String
        var diagnosisCode: String
        var amount: Double
        var status: StrictDenialTargetStatus

        init(code: String, label: String, active: Bool, locale: String, ownerID: String, diagnosisCode: String, amount: Double, status: StrictDenialTargetStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.locale = locale
            self.ownerID = ownerID
            self.diagnosisCode = diagnosisCode
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictDenialTargetStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == StrictDenialTargetStatus.revoked
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: StrictDenialTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict denial target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("strict denial target") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> StrictDenialTarget {
            return StrictDenialTarget(
                code: code,
                label: label,
                active: active,
                locale: locale,
                ownerID: ownerID,
                diagnosisCode: diagnosisCode,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a strict denial target in status requested.
    static func newStrictDenialTarget(_ code: String, label: String) -> StrictDenialTarget {
        return StrictDenialTarget(
            code: code,
            label: label,
            active: false,
            locale: "",
            ownerID: "",
            diagnosisCode: "",
            amount: 0.0,
            status: StrictDenialTargetStatus.requested
        )
    }
}
