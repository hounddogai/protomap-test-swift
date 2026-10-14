import AcmePlatform
import Foundation

extension Labs {
    /// Where a default reference range variance is in its life cycle.
    enum DefaultReferenceRangeVarianceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a default reference range variance and its current status.
    final class DefaultReferenceRangeVariance {
        var code: String
        var title: String
        var country: String
        var payer: String
        var active: Bool
        var createdAt: Int
        var dosageMg: Double
        var ceiling: Double
        var visitMinutes: Int
        var status: DefaultReferenceRangeVarianceStatus

        init(code: String, title: String, country: String, payer: String, active: Bool, createdAt: Int, dosageMg: Double, ceiling: Double, visitMinutes: Int, status: DefaultReferenceRangeVarianceStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.payer = payer
            self.active = active
            self.createdAt = createdAt
            self.dosageMg = dosageMg
            self.ceiling = ceiling
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultReferenceRangeVarianceStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == DefaultReferenceRangeVarianceStatus.rejected || next == DefaultReferenceRangeVarianceStatus.withdrawn
            case .rejected:
                return next == DefaultReferenceRangeVarianceStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultReferenceRangeVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default reference range variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("default reference range variance") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(visitMinutes) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> DefaultReferenceRangeVariance {
            return DefaultReferenceRangeVariance(
                code: code,
                title: title,
                country: country,
                payer: payer,
                active: active,
                createdAt: createdAt,
                dosageMg: dosageMg,
                ceiling: ceiling,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a default reference range variance in status proposed.
    static func newDefaultReferenceRangeVariance(_ code: String, title: String) -> DefaultReferenceRangeVariance {
        return DefaultReferenceRangeVariance(
            code: code,
            title: title,
            country: "",
            payer: "",
            active: false,
            createdAt: 0,
            dosageMg: 0.0,
            ceiling: 0.0,
            visitMinutes: 0,
            status: DefaultReferenceRangeVarianceStatus.proposed
        )
    }
}
