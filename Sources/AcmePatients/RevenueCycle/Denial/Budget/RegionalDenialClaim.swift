import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a regional denial claim is in its life cycle.
    enum RegionalDenialClaimStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a regional denial claim and its current status.
    final class RegionalDenialClaim {
        var code: String
        var title: String
        var ward: String
        var updatedAt: Int
        var facility: String
        var score: Double
        var category: String
        var minimum: Double
        var status: RegionalDenialClaimStatus

        init(code: String, title: String, ward: String, updatedAt: Int, facility: String, score: Double, category: String, minimum: Double, status: RegionalDenialClaimStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.updatedAt = updatedAt
            self.facility = facility
            self.score = score
            self.category = category
            self.minimum = minimum
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

        func canMoveTo(_ next: RegionalDenialClaimStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == RegionalDenialClaimStatus.suspended || next == RegionalDenialClaimStatus.closed
            case .suspended:
                return next == RegionalDenialClaimStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalDenialClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional denial claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netLoad() -> Double {
            return ((score + minimum) * 100).rounded() / 100
        }

        func copyValue() -> RegionalDenialClaim {
            return RegionalDenialClaim(
                code: code,
                title: title,
                ward: ward,
                updatedAt: updatedAt,
                facility: facility,
                score: score,
                category: category,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a regional denial claim in status draft.
    static func newRegionalDenialClaim(_ code: String, title: String) -> RegionalDenialClaim {
        return RegionalDenialClaim(
            code: code,
            title: title,
            ward: "",
            updatedAt: 0,
            facility: "",
            score: 0.0,
            category: "",
            minimum: 0.0,
            status: RegionalDenialClaimStatus.draft
        )
    }
}
