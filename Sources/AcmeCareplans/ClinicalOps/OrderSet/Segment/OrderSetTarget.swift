import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set target is in its life cycle.
    enum OrderSetTargetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A order set target as the order set team keeps it.
    final class OrderSetTarget {
        var code: String
        var name: String
        var floorValue: Double
        var attributes: [String: String]
        var version: Int
        var minimum: Double
        var notes: String
        var region: String
        var status: OrderSetTargetStatus

        init(code: String, name: String, floorValue: Double, attributes: [String: String], version: Int, minimum: Double, notes: String, region: String, status: OrderSetTargetStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.attributes = attributes
            self.version = version
            self.minimum = minimum
            self.notes = notes
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OrderSetTargetStatus) -> Bool {
            switch status {
            case .created:
                return next == OrderSetTargetStatus.validated || next == OrderSetTargetStatus.published
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: OrderSetTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
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

        func effectiveValue() -> Double {
            return (Double(version) * minimum * 100).rounded() / 100
        }

        func copyValue() -> OrderSetTarget {
            return OrderSetTarget(
                code: code,
                name: name,
                floorValue: floorValue,
                attributes: attributes,
                version: version,
                minimum: minimum,
                notes: notes,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a order set target in status created.
    static func newOrderSetTarget(_ code: String, name: String) -> OrderSetTarget {
        return OrderSetTarget(
            code: code,
            name: name,
            floorValue: 0.0,
            attributes: [:],
            version: 0,
            minimum: 0.0,
            notes: "",
            region: "",
            status: OrderSetTargetStatus.created
        )
    }
}
