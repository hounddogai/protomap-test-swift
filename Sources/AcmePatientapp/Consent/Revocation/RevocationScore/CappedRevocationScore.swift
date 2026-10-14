import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped revocation score is in its life cycle.
    enum CappedRevocationScoreStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a capped revocation score and its current status.
    final class CappedRevocationScore {
        var code: String
        var name: String
        var discount: Double
        var copay: Double
        var createdAt: Int
        var cost: Double
        var status: CappedRevocationScoreStatus

        init(code: String, name: String, discount: Double, copay: Double, createdAt: Int, cost: Double, status: CappedRevocationScoreStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.copay = copay
            self.createdAt = createdAt
            self.cost = cost
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

        func canMoveTo(_ next: CappedRevocationScoreStatus) -> Bool {
            switch status {
            case .draft:
                return next == CappedRevocationScoreStatus.pending
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == CappedRevocationScoreStatus.suspended
            case .suspended:
                return next == CappedRevocationScoreStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedRevocationScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped revocation score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedTotal() -> Double {
            return ((cost + copay) * 100).rounded() / 100
        }

        func copyValue() -> CappedRevocationScore {
            return CappedRevocationScore(
                code: code,
                name: name,
                discount: discount,
                copay: copay,
                createdAt: createdAt,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped revocation score in status draft.
    static func newCappedRevocationScore(_ code: String, name: String) -> CappedRevocationScore {
        return CappedRevocationScore(
            code: code,
            name: name,
            discount: 0.0,
            copay: 0.0,
            createdAt: 0,
            cost: 0.0,
            status: CappedRevocationScoreStatus.draft
        )
    }
}
