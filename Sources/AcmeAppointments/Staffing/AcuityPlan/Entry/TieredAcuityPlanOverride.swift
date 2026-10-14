import AcmePlatform
import Foundation

extension Staffing {
    /// Where a tiered acuity plan override is in its life cycle.
    enum TieredAcuityPlanOverrideStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A tiered acuity plan override as the acuity plan team keeps it.
    final class TieredAcuityPlanOverride {
        var code: String
        var name: String
        var rate: Double
        var minimum: Double
        var weight: Double
        var source: String
        var externalRef: String
        var maximum: Double
        var budget: Double
        var locale: String
        var status: TieredAcuityPlanOverrideStatus

        init(code: String, name: String, rate: Double, minimum: Double, weight: Double, source: String, externalRef: String, maximum: Double, budget: Double, locale: String, status: TieredAcuityPlanOverrideStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.minimum = minimum
            self.weight = weight
            self.source = source
            self.externalRef = externalRef
            self.maximum = maximum
            self.budget = budget
            self.locale = locale
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

        func canMoveTo(_ next: TieredAcuityPlanOverrideStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == TieredAcuityPlanOverrideStatus.rejected || next == TieredAcuityPlanOverrideStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: TieredAcuityPlanOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered acuity plan override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedExposure() -> Double {
            return ((weight - minimum) * 100).rounded() / 100
        }

        func copyValue() -> TieredAcuityPlanOverride {
            return TieredAcuityPlanOverride(
                code: code,
                name: name,
                rate: rate,
                minimum: minimum,
                weight: weight,
                source: source,
                externalRef: externalRef,
                maximum: maximum,
                budget: budget,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a tiered acuity plan override in status proposed.
    static func newTieredAcuityPlanOverride(_ code: String, name: String) -> TieredAcuityPlanOverride {
        return TieredAcuityPlanOverride(
            code: code,
            name: name,
            rate: 0.0,
            minimum: 0.0,
            weight: 0.0,
            source: "",
            externalRef: "",
            maximum: 0.0,
            budget: 0.0,
            locale: "",
            status: TieredAcuityPlanOverrideStatus.proposed
        )
    }
}
