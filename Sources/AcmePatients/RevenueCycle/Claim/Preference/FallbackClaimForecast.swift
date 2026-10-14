import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback claim forecast is in its life cycle.
    enum FallbackClaimForecastStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A fallback claim forecast. Its code is unique within a tenant.
    final class FallbackClaimForecast {
        var code: String
        var name: String
        var patientRef: String
        var expiresAt: Int
        var bed: String
        var updatedAt: Int
        var discount: Double
        var quantity: Int
        var ratio: Double
        var status: FallbackClaimForecastStatus

        init(code: String, name: String, patientRef: String, expiresAt: Int, bed: String, updatedAt: Int, discount: Double, quantity: Int, ratio: Double, status: FallbackClaimForecastStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.expiresAt = expiresAt
            self.bed = bed
            self.updatedAt = updatedAt
            self.discount = discount
            self.quantity = quantity
            self.ratio = ratio
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

        func canMoveTo(_ next: FallbackClaimForecastStatus) -> Bool {
            switch status {
            case .`open`:
                return next == FallbackClaimForecastStatus.reopened || next == FallbackClaimForecastStatus.archived
            case .inReview:
                return next == FallbackClaimForecastStatus.reopened || next == FallbackClaimForecastStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == FallbackClaimForecastStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackClaimForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback claim forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("fallback claim forecast") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(expiresAt) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackClaimForecast {
            return FallbackClaimForecast(
                code: code,
                name: name,
                patientRef: patientRef,
                expiresAt: expiresAt,
                bed: bed,
                updatedAt: updatedAt,
                discount: discount,
                quantity: quantity,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback claim forecast in status open.
    static func newFallbackClaimForecast(_ code: String, name: String) -> FallbackClaimForecast {
        return FallbackClaimForecast(
            code: code,
            name: name,
            patientRef: "",
            expiresAt: 0,
            bed: "",
            updatedAt: 0,
            discount: 0.0,
            quantity: 0,
            ratio: 0.0,
            status: FallbackClaimForecastStatus.`open`
        )
    }
}
