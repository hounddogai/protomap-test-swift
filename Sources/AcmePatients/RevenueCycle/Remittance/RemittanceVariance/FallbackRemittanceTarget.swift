import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback remittance target is in its life cycle.
    enum FallbackRemittanceTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A fallback remittance target as the remittance team keeps it.
    final class FallbackRemittanceTarget {
        var code: String
        var title: String
        var attempts: Int
        var allergy: String
        var threshold: Double
        var region: String
        var name: String
        var procedureCode: String
        var status: FallbackRemittanceTargetStatus

        init(code: String, title: String, attempts: Int, allergy: String, threshold: Double, region: String, name: String, procedureCode: String, status: FallbackRemittanceTargetStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.allergy = allergy
            self.threshold = threshold
            self.region = region
            self.name = name
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: FallbackRemittanceTargetStatus) -> Bool {
            switch status {
            case .`open`:
                return next == FallbackRemittanceTargetStatus.inReview || next == FallbackRemittanceTargetStatus.resolved
            case .inReview:
                return next == FallbackRemittanceTargetStatus.resolved
            case .resolved:
                switch next {
                case .archived:
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

        func moveTo(_ next: FallbackRemittanceTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback remittance target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback remittance target") \(code)"
        }

        func adjustedValue() -> Double {
            return ((threshold - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackRemittanceTarget {
            return FallbackRemittanceTarget(
                code: code,
                title: title,
                attempts: attempts,
                allergy: allergy,
                threshold: threshold,
                region: region,
                name: name,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a fallback remittance target in status open.
    static func newFallbackRemittanceTarget(_ code: String, title: String) -> FallbackRemittanceTarget {
        return FallbackRemittanceTarget(
            code: code,
            title: title,
            attempts: 0,
            allergy: "",
            threshold: 0.0,
            region: "",
            name: "",
            procedureCode: "",
            status: FallbackRemittanceTargetStatus.`open`
        )
    }
}
