import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial plan is in its life cycle.
    enum DenialPlanStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A denial plan. Its code is unique within a tenant.
    final class DenialPlan {
        var code: String
        var title: String
        var country: String
        var endsAt: Int
        var source: String
        var unit: String
        var status: DenialPlanStatus

        init(code: String, title: String, country: String, endsAt: Int, source: String, unit: String, status: DenialPlanStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.endsAt = endsAt
            self.source = source
            self.unit = unit
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

        func canMoveTo(_ next: DenialPlanStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DenialPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> DenialPlan {
            return DenialPlan(
                code: code,
                title: title,
                country: country,
                endsAt: endsAt,
                source: source,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a denial plan in status requested.
    static func newDenialPlan(_ code: String, title: String) -> DenialPlan {
        return DenialPlan(
            code: code,
            title: title,
            country: "",
            endsAt: 0,
            source: "",
            unit: "",
            status: DenialPlanStatus.requested
        )
    }
}
