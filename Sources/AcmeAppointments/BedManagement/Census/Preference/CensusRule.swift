import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census rule is in its life cycle.
    enum CensusRuleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One census rule, with what the planners need to act on it.
    final class CensusRule {
        var code: String
        var name: String
        var amount: Double
        var title: String
        var source: String
        var durationMinutes: Int
        var facility: String
        var expiresAt: Int
        var status: CensusRuleStatus

        init(code: String, name: String, amount: Double, title: String, source: String, durationMinutes: Int, facility: String, expiresAt: Int, status: CensusRuleStatus) {
            self.code = code
            self.name = name
            self.amount = amount
            self.title = title
            self.source = source
            self.durationMinutes = durationMinutes
            self.facility = facility
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: CensusRuleStatus) -> Bool {
            switch status {
            case .requested:
                return next == CensusRuleStatus.granted || next == CensusRuleStatus.revoked
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

        func moveTo(_ next: CensusRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("census rule") \(code)"
        }

        func netVolume() -> Double {
            return (Double(durationMinutes) * amount * 100).rounded() / 100
        }

        func copyValue() -> CensusRule {
            return CensusRule(
                code: code,
                name: name,
                amount: amount,
                title: title,
                source: source,
                durationMinutes: durationMinutes,
                facility: facility,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a census rule in status requested.
    static func newCensusRule(_ code: String, name: String) -> CensusRule {
        return CensusRule(
            code: code,
            name: name,
            amount: 0.0,
            title: "",
            source: "",
            durationMinutes: 0,
            facility: "",
            expiresAt: 0,
            status: CensusRuleStatus.requested
        )
    }
}
