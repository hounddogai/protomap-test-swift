import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback denial baseline is in its life cycle.
    enum FallbackDenialBaselineStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A fallback denial baseline as the denial team keeps it.
    final class FallbackDenialBaseline {
        var code: String
        var name: String
        var patientRef: String
        var minimum: Double
        var externalRef: String
        var source: String
        var discount: Double
        var margin: Double
        var active: Bool
        var status: FallbackDenialBaselineStatus

        init(code: String, name: String, patientRef: String, minimum: Double, externalRef: String, source: String, discount: Double, margin: Double, active: Bool, status: FallbackDenialBaselineStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.minimum = minimum
            self.externalRef = externalRef
            self.source = source
            self.discount = discount
            self.margin = margin
            self.active = active
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

        func canMoveTo(_ next: FallbackDenialBaselineStatus) -> Bool {
            switch status {
            case .draft:
                return next == FallbackDenialBaselineStatus.active || next == FallbackDenialBaselineStatus.closed
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
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == FallbackDenialBaselineStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackDenialBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback denial baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback denial baseline") \(code)"
        }

        func projectedTotal() -> Double {
            return (margin * minimum * 100).rounded() / 100
        }

        func copyValue() -> FallbackDenialBaseline {
            return FallbackDenialBaseline(
                code: code,
                name: name,
                patientRef: patientRef,
                minimum: minimum,
                externalRef: externalRef,
                source: source,
                discount: discount,
                margin: margin,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a fallback denial baseline in status draft.
    static func newFallbackDenialBaseline(_ code: String, name: String) -> FallbackDenialBaseline {
        return FallbackDenialBaseline(
            code: code,
            name: name,
            patientRef: "",
            minimum: 0.0,
            externalRef: "",
            source: "",
            discount: 0.0,
            margin: 0.0,
            active: false,
            status: FallbackDenialBaselineStatus.draft
        )
    }
}
