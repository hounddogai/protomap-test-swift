import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a regional inventory request is in its life cycle.
    enum RegionalInventoryRequestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A regional inventory request. Its code is unique within a tenant.
    final class RegionalInventoryRequest {
        var code: String
        var title: String
        var segment: String
        var budget: Double
        var specialty: String
        var expiresAt: Int
        var status: RegionalInventoryRequestStatus

        init(code: String, title: String, segment: String, budget: Double, specialty: String, expiresAt: Int, status: RegionalInventoryRequestStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.budget = budget
            self.specialty = specialty
            self.expiresAt = expiresAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalInventoryRequestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RegionalInventoryRequestStatus.inReview
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == RegionalInventoryRequestStatus.reopened || next == RegionalInventoryRequestStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: RegionalInventoryRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional inventory request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedLoad() -> Double {
            return (budget * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> RegionalInventoryRequest {
            return RegionalInventoryRequest(
                code: code,
                title: title,
                segment: segment,
                budget: budget,
                specialty: specialty,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a regional inventory request in status open.
    static func newRegionalInventoryRequest(_ code: String, title: String) -> RegionalInventoryRequest {
        return RegionalInventoryRequest(
            code: code,
            title: title,
            segment: "",
            budget: 0.0,
            specialty: "",
            expiresAt: 0,
            status: RegionalInventoryRequestStatus.`open`
        )
    }
}
