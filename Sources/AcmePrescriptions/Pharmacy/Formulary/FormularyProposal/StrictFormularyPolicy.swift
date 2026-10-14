import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a strict formulary policy is in its life cycle.
    enum StrictFormularyPolicyStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One strict formulary policy, with what the planners need to act on it.
    final class StrictFormularyPolicy {
        var code: String
        var label: String
        var windowDays: Int
        var externalRef: String
        var capacity: Int
        var notes: String
        var payer: String
        var locale: String
        var clinicianID: String
        var status: StrictFormularyPolicyStatus

        init(code: String, label: String, windowDays: Int, externalRef: String, capacity: Int, notes: String, payer: String, locale: String, clinicianID: String, status: StrictFormularyPolicyStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.externalRef = externalRef
            self.capacity = capacity
            self.notes = notes
            self.payer = payer
            self.locale = locale
            self.clinicianID = clinicianID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictFormularyPolicyStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StrictFormularyPolicyStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: StrictFormularyPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict formulary policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("strict formulary policy") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(capacity) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> StrictFormularyPolicy {
            return StrictFormularyPolicy(
                code: code,
                label: label,
                windowDays: windowDays,
                externalRef: externalRef,
                capacity: capacity,
                notes: notes,
                payer: payer,
                locale: locale,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a strict formulary policy in status proposed.
    static func newStrictFormularyPolicy(_ code: String, label: String) -> StrictFormularyPolicy {
        return StrictFormularyPolicy(
            code: code,
            label: label,
            windowDays: 0,
            externalRef: "",
            capacity: 0,
            notes: "",
            payer: "",
            locale: "",
            clinicianID: "",
            status: StrictFormularyPolicyStatus.proposed
        )
    }
}
