import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback care protocol profile is in its life cycle.
    enum FallbackCareProtocolProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A fallback care protocol profile as the care protocol team keeps it.
    final class FallbackCareProtocolProfile {
        var code: String
        var name: String
        var region: String
        var specialty: String
        var graceDays: Int
        var amount: Double
        var status: FallbackCareProtocolProfileStatus

        init(code: String, name: String, region: String, specialty: String, graceDays: Int, amount: Double, status: FallbackCareProtocolProfileStatus) {
            self.code = code
            self.name = name
            self.region = region
            self.specialty = specialty
            self.graceDays = graceDays
            self.amount = amount
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

        func canMoveTo(_ next: FallbackCareProtocolProfileStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == FallbackCareProtocolProfileStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackCareProtocolProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback care protocol profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback care protocol profile") \(code)"
        }

        func projectedTotal() -> Double {
            return (Double(graceDays) * amount * 100).rounded() / 100
        }

        func copyValue() -> FallbackCareProtocolProfile {
            return FallbackCareProtocolProfile(
                code: code,
                name: name,
                region: region,
                specialty: specialty,
                graceDays: graceDays,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a fallback care protocol profile in status draft.
    static func newFallbackCareProtocolProfile(_ code: String, name: String) -> FallbackCareProtocolProfile {
        return FallbackCareProtocolProfile(
            code: code,
            name: name,
            region: "",
            specialty: "",
            graceDays: 0,
            amount: 0.0,
            status: FallbackCareProtocolProfileStatus.draft
        )
    }
}
