import AcmePlatform
import Foundation

extension Consent {
    /// Where a weighted witness rollup is in its life cycle.
    enum WeightedWitnessRollupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A weighted witness rollup. Its code is unique within a tenant.
    final class WeightedWitnessRollup {
        var code: String
        var label: String
        var priority: Int
        var category: String
        var endsAt: Int
        var facility: String
        var ownerID: String
        var expiresAt: Int
        var externalRef: String
        var attributes: [String: String]
        var status: WeightedWitnessRollupStatus

        init(code: String, label: String, priority: Int, category: String, endsAt: Int, facility: String, ownerID: String, expiresAt: Int, externalRef: String, attributes: [String: String], status: WeightedWitnessRollupStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.category = category
            self.endsAt = endsAt
            self.facility = facility
            self.ownerID = ownerID
            self.expiresAt = expiresAt
            self.externalRef = externalRef
            self.attributes = attributes
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

        func canMoveTo(_ next: WeightedWitnessRollupStatus) -> Bool {
            switch status {
            case .proposed:
                return next == WeightedWitnessRollupStatus.approved || next == WeightedWitnessRollupStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == WeightedWitnessRollupStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedWitnessRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted witness rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func netExposure() -> Double {
            return (Double(expiresAt) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> WeightedWitnessRollup {
            return WeightedWitnessRollup(
                code: code,
                label: label,
                priority: priority,
                category: category,
                endsAt: endsAt,
                facility: facility,
                ownerID: ownerID,
                expiresAt: expiresAt,
                externalRef: externalRef,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a weighted witness rollup in status proposed.
    static func newWeightedWitnessRollup(_ code: String, label: String) -> WeightedWitnessRollup {
        return WeightedWitnessRollup(
            code: code,
            label: label,
            priority: 0,
            category: "",
            endsAt: 0,
            facility: "",
            ownerID: "",
            expiresAt: 0,
            externalRef: "",
            attributes: [:],
            status: WeightedWitnessRollupStatus.proposed
        )
    }
}
