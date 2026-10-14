import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient proxy claim is in its life cycle.
    enum LenientProxyClaimStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a lenient proxy claim and its current status.
    final class LenientProxyClaim {
        var code: String
        var name: String
        var ward: String
        var discount: Double
        var title: String
        var budget: Double
        var status: LenientProxyClaimStatus

        init(code: String, name: String, ward: String, discount: Double, title: String, budget: Double, status: LenientProxyClaimStatus) {
            self.code = code
            self.name = name
            self.ward = ward
            self.discount = discount
            self.title = title
            self.budget = budget
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

        func canMoveTo(_ next: LenientProxyClaimStatus) -> Bool {
            switch status {
            case .draft:
                return next == LenientProxyClaimStatus.active || next == LenientProxyClaimStatus.suspended
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == LenientProxyClaimStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientProxyClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient proxy claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedTotal() -> Double {
            return ((budget + discount) * 100).rounded() / 100
        }

        func copyValue() -> LenientProxyClaim {
            return LenientProxyClaim(
                code: code,
                name: name,
                ward: ward,
                discount: discount,
                title: title,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a lenient proxy claim in status draft.
    static func newLenientProxyClaim(_ code: String, name: String) -> LenientProxyClaim {
        return LenientProxyClaim(
            code: code,
            name: name,
            ward: "",
            discount: 0.0,
            title: "",
            budget: 0.0,
            status: LenientProxyClaimStatus.draft
        )
    }
}
