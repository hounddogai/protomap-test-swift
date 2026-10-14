import AcmePlatform
import Foundation

extension Staffing {
    /// Where a fallback shift baseline is in its life cycle.
    enum FallbackShiftBaselineStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One fallback shift baseline, with what the planners need to act on it.
    final class FallbackShiftBaseline {
        var code: String
        var name: String
        var unit: String
        var threshold: Double
        var expiresAt: Int
        var quantity: Int
        var status: FallbackShiftBaselineStatus

        init(code: String, name: String, unit: String, threshold: Double, expiresAt: Int, quantity: Int, status: FallbackShiftBaselineStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.threshold = threshold
            self.expiresAt = expiresAt
            self.quantity = quantity
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

        func canMoveTo(_ next: FallbackShiftBaselineStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: FallbackShiftBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback shift baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("fallback shift baseline") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(expiresAt) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackShiftBaseline {
            return FallbackShiftBaseline(
                code: code,
                name: name,
                unit: unit,
                threshold: threshold,
                expiresAt: expiresAt,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a fallback shift baseline in status open.
    static func newFallbackShiftBaseline(_ code: String, name: String) -> FallbackShiftBaseline {
        return FallbackShiftBaseline(
            code: code,
            name: name,
            unit: "",
            threshold: 0.0,
            expiresAt: 0,
            quantity: 0,
            status: FallbackShiftBaselineStatus.`open`
        )
    }
}
