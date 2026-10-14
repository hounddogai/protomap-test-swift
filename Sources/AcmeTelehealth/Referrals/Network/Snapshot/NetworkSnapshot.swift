import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network snapshot is in its life cycle.
    enum NetworkSnapshotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A network snapshot. Its code is unique within a tenant.
    final class NetworkSnapshot {
        var code: String
        var label: String
        var name: String
        var weight: Double
        var attributes: [String: String]
        var segment: String
        var budget: Double
        var minimum: Double
        var status: NetworkSnapshotStatus

        init(code: String, label: String, name: String, weight: Double, attributes: [String: String], segment: String, budget: Double, minimum: Double, status: NetworkSnapshotStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.weight = weight
            self.attributes = attributes
            self.segment = segment
            self.budget = budget
            self.minimum = minimum
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

        func canMoveTo(_ next: NetworkSnapshotStatus) -> Bool {
            switch status {
            case .proposed:
                return next == NetworkSnapshotStatus.approved
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == NetworkSnapshotStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
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

        func weightedExposure() -> Double {
            return (minimum * budget * 100).rounded() / 100
        }

        func copyValue() -> NetworkSnapshot {
            return NetworkSnapshot(
                code: code,
                label: label,
                name: name,
                weight: weight,
                attributes: attributes,
                segment: segment,
                budget: budget,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a network snapshot in status proposed.
    static func newNetworkSnapshot(_ code: String, label: String) -> NetworkSnapshot {
        return NetworkSnapshot(
            code: code,
            label: label,
            name: "",
            weight: 0.0,
            attributes: [:],
            segment: "",
            budget: 0.0,
            minimum: 0.0,
            status: NetworkSnapshotStatus.proposed
        )
    }
}
