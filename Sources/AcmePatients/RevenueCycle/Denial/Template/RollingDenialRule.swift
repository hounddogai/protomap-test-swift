import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a rolling denial rule is in its life cycle.
    enum RollingDenialRuleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A rolling denial rule as the denial team keeps it.
    final class RollingDenialRule {
        var code: String
        var title: String
        var createdAt: Int
        var phone: String
        var visitMinutes: Int
        var startsAt: Int
        var country: String
        var discount: Double
        var externalRef: String
        var specialty: String
        var category: String
        var status: RollingDenialRuleStatus

        init(code: String, title: String, createdAt: Int, phone: String, visitMinutes: Int, startsAt: Int, country: String, discount: Double, externalRef: String, specialty: String, category: String, status: RollingDenialRuleStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.phone = phone
            self.visitMinutes = visitMinutes
            self.startsAt = startsAt
            self.country = country
            self.discount = discount
            self.externalRef = externalRef
            self.specialty = specialty
            self.category = category
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

        func canMoveTo(_ next: RollingDenialRuleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == RollingDenialRuleStatus.stopped
            case .ready:
                return next == RollingDenialRuleStatus.draining
            case .draining:
                return next == RollingDenialRuleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingDenialRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling denial rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netVolume() -> Double {
            return (discount * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> RollingDenialRule {
            return RollingDenialRule(
                code: code,
                title: title,
                createdAt: createdAt,
                phone: phone,
                visitMinutes: visitMinutes,
                startsAt: startsAt,
                country: country,
                discount: discount,
                externalRef: externalRef,
                specialty: specialty,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a rolling denial rule in status idle.
    static func newRollingDenialRule(_ code: String, title: String) -> RollingDenialRule {
        return RollingDenialRule(
            code: code,
            title: title,
            createdAt: 0,
            phone: "",
            visitMinutes: 0,
            startsAt: 0,
            country: "",
            discount: 0.0,
            externalRef: "",
            specialty: "",
            category: "",
            status: RollingDenialRuleStatus.idle
        )
    }
}
