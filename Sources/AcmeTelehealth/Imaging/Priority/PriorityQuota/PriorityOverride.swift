import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority override is in its life cycle.
    enum PriorityOverrideStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A priority override as the priority team keeps it.
    final class PriorityOverride {
        var code: String
        var label: String
        var batchSize: Int
        var country: String
        var budget: Double
        var allergy: String
        var reviewer: String
        var sequence: Int
        var timezone: String
        var status: PriorityOverrideStatus

        init(code: String, label: String, batchSize: Int, country: String, budget: Double, allergy: String, reviewer: String, sequence: Int, timezone: String, status: PriorityOverrideStatus) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.country = country
            self.budget = budget
            self.allergy = allergy
            self.reviewer = reviewer
            self.sequence = sequence
            self.timezone = timezone
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

        func canMoveTo(_ next: PriorityOverrideStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == PriorityOverrideStatus.revoked || next == PriorityOverrideStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: PriorityOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("priority override") \(code)"
        }

        func projectedTotal() -> Double {
            return (Double(batchSize) * budget * 100).rounded() / 100
        }

        func copyValue() -> PriorityOverride {
            return PriorityOverride(
                code: code,
                label: label,
                batchSize: batchSize,
                country: country,
                budget: budget,
                allergy: allergy,
                reviewer: reviewer,
                sequence: sequence,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a priority override in status requested.
    static func newPriorityOverride(_ code: String, label: String) -> PriorityOverride {
        return PriorityOverride(
            code: code,
            label: label,
            batchSize: 0,
            country: "",
            budget: 0.0,
            allergy: "",
            reviewer: "",
            sequence: 0,
            timezone: "",
            status: PriorityOverrideStatus.requested
        )
    }
}
