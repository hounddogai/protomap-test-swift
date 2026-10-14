import AcmePlatform
import Foundation

extension Staffing {
    /// Where a regional acuity plan claim is in its life cycle.
    enum RegionalAcuityPlanClaimStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A regional acuity plan claim as the acuity plan team keeps it.
    final class RegionalAcuityPlanClaim {
        var code: String
        var name: String
        var visible: Bool
        var expiresAt: Int
        var title: String
        var score: Double
        var status: RegionalAcuityPlanClaimStatus

        init(code: String, name: String, visible: Bool, expiresAt: Int, title: String, score: Double, status: RegionalAcuityPlanClaimStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.expiresAt = expiresAt
            self.title = title
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalAcuityPlanClaimStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RegionalAcuityPlanClaimStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalAcuityPlanClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional acuity plan claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("regional acuity plan claim") \(code)"
        }

        func weightedTotal() -> Double {
            return (score * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> RegionalAcuityPlanClaim {
            return RegionalAcuityPlanClaim(
                code: code,
                name: name,
                visible: visible,
                expiresAt: expiresAt,
                title: title,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional acuity plan claim in status created.
    static func newRegionalAcuityPlanClaim(_ code: String, name: String) -> RegionalAcuityPlanClaim {
        return RegionalAcuityPlanClaim(
            code: code,
            name: name,
            visible: false,
            expiresAt: 0,
            title: "",
            score: 0.0,
            status: RegionalAcuityPlanClaimStatus.created
        )
    }
}
