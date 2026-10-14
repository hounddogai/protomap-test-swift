import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy panel agreement is in its life cycle.
    enum LegacyPanelAgreementStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One legacy panel agreement, with what the planners need to act on it.
    final class LegacyPanelAgreement {
        var code: String
        var name: String
        var unit: String
        var active: Bool
        var visitMinutes: Int
        var cost: Double
        var budget: Double
        var status: LegacyPanelAgreementStatus

        init(code: String, name: String, unit: String, active: Bool, visitMinutes: Int, cost: Double, budget: Double, status: LegacyPanelAgreementStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.active = active
            self.visitMinutes = visitMinutes
            self.cost = cost
            self.budget = budget
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

        func canMoveTo(_ next: LegacyPanelAgreementStatus) -> Bool {
            switch status {
            case .requested:
                return next == LegacyPanelAgreementStatus.revoked || next == LegacyPanelAgreementStatus.expired
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

        func moveTo(_ next: LegacyPanelAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy panel agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netValue() -> Double {
            return ((Double(visitMinutes) + budget) * 100).rounded() / 100
        }

        func copyValue() -> LegacyPanelAgreement {
            return LegacyPanelAgreement(
                code: code,
                name: name,
                unit: unit,
                active: active,
                visitMinutes: visitMinutes,
                cost: cost,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a legacy panel agreement in status requested.
    static func newLegacyPanelAgreement(_ code: String, name: String) -> LegacyPanelAgreement {
        return LegacyPanelAgreement(
            code: code,
            name: name,
            unit: "",
            active: false,
            visitMinutes: 0,
            cost: 0.0,
            budget: 0.0,
            status: LegacyPanelAgreementStatus.requested
        )
    }
}
