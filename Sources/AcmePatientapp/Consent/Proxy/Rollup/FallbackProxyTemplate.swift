import AcmePlatform
import Foundation

extension Consent {
    /// Where a fallback proxy template is in its life cycle.
    enum FallbackProxyTemplateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One fallback proxy template, with what the planners need to act on it.
    final class FallbackProxyTemplate {
        var code: String
        var title: String
        var budget: Double
        var ward: String
        var reviewer: String
        var procedureCode: String
        var attempts: Int
        var specialty: String
        var quantity: Int
        var endsAt: Int
        var dosageMg: Double
        var status: FallbackProxyTemplateStatus

        init(code: String, title: String, budget: Double, ward: String, reviewer: String, procedureCode: String, attempts: Int, specialty: String, quantity: Int, endsAt: Int, dosageMg: Double, status: FallbackProxyTemplateStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.ward = ward
            self.reviewer = reviewer
            self.procedureCode = procedureCode
            self.attempts = attempts
            self.specialty = specialty
            self.quantity = quantity
            self.endsAt = endsAt
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackProxyTemplateStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == FallbackProxyTemplateStatus.done || next == FallbackProxyTemplateStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: FallbackProxyTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback proxy template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveValue() -> Double {
            return (dosageMg * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> FallbackProxyTemplate {
            return FallbackProxyTemplate(
                code: code,
                title: title,
                budget: budget,
                ward: ward,
                reviewer: reviewer,
                procedureCode: procedureCode,
                attempts: attempts,
                specialty: specialty,
                quantity: quantity,
                endsAt: endsAt,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a fallback proxy template in status new.
    static func newFallbackProxyTemplate(_ code: String, title: String) -> FallbackProxyTemplate {
        return FallbackProxyTemplate(
            code: code,
            title: title,
            budget: 0.0,
            ward: "",
            reviewer: "",
            procedureCode: "",
            attempts: 0,
            specialty: "",
            quantity: 0,
            endsAt: 0,
            dosageMg: 0.0,
            status: FallbackProxyTemplateStatus.new
        )
    }
}
