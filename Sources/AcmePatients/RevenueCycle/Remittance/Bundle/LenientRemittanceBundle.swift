import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient remittance bundle is in its life cycle.
    enum LenientRemittanceBundleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A lenient remittance bundle as the remittance team keeps it.
    final class LenientRemittanceBundle {
        var code: String
        var title: String
        var amount: Double
        var diagnosisCode: String
        var rate: Double
        var name: String
        var status: LenientRemittanceBundleStatus

        init(code: String, title: String, amount: Double, diagnosisCode: String, rate: Double, name: String, status: LenientRemittanceBundleStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.diagnosisCode = diagnosisCode
            self.rate = rate
            self.name = name
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

        func canMoveTo(_ next: LenientRemittanceBundleStatus) -> Bool {
            switch status {
            case .draft:
                return next == LenientRemittanceBundleStatus.pending
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == LenientRemittanceBundleStatus.suspended
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

        func moveTo(_ next: LenientRemittanceBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient remittance bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedExposure() -> Double {
            return (rate * amount * 100).rounded() / 100
        }

        func copyValue() -> LenientRemittanceBundle {
            return LenientRemittanceBundle(
                code: code,
                title: title,
                amount: amount,
                diagnosisCode: diagnosisCode,
                rate: rate,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient remittance bundle in status draft.
    static func newLenientRemittanceBundle(_ code: String, title: String) -> LenientRemittanceBundle {
        return LenientRemittanceBundle(
            code: code,
            title: title,
            amount: 0.0,
            diagnosisCode: "",
            rate: 0.0,
            name: "",
            status: LenientRemittanceBundleStatus.draft
        )
    }
}
