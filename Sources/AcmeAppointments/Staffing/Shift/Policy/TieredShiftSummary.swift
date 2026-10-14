import AcmePlatform
import Foundation

extension Staffing {
    /// Where a tiered shift summary is in its life cycle.
    enum TieredShiftSummaryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One tiered shift summary, with what the planners need to act on it.
    final class TieredShiftSummary {
        var code: String
        var title: String
        var updatedAt: Int
        var minimum: Double
        var contactEmail: String
        var margin: Double
        var dosageMg: Double
        var createdAt: Int
        var status: TieredShiftSummaryStatus

        init(code: String, title: String, updatedAt: Int, minimum: Double, contactEmail: String, margin: Double, dosageMg: Double, createdAt: Int, status: TieredShiftSummaryStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.minimum = minimum
            self.contactEmail = contactEmail
            self.margin = margin
            self.dosageMg = dosageMg
            self.createdAt = createdAt
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

        func canMoveTo(_ next: TieredShiftSummaryStatus) -> Bool {
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
                return next == TieredShiftSummaryStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredShiftSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered shift summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("tiered shift summary") \(code)"
        }

        func adjustedLoad() -> Double {
            return (minimum * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> TieredShiftSummary {
            return TieredShiftSummary(
                code: code,
                title: title,
                updatedAt: updatedAt,
                minimum: minimum,
                contactEmail: contactEmail,
                margin: margin,
                dosageMg: dosageMg,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered shift summary in status requested.
    static func newTieredShiftSummary(_ code: String, title: String) -> TieredShiftSummary {
        return TieredShiftSummary(
            code: code,
            title: title,
            updatedAt: 0,
            minimum: 0.0,
            contactEmail: "",
            margin: 0.0,
            dosageMg: 0.0,
            createdAt: 0,
            status: TieredShiftSummaryStatus.requested
        )
    }
}
