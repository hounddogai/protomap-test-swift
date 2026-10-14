import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a fallback inventory target is in its life cycle.
    enum FallbackInventoryTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A fallback inventory target. Its code is unique within a tenant.
    final class FallbackInventoryTarget {
        var code: String
        var name: String
        var source: String
        var capacity: Int
        var attributes: [String: String]
        var ratio: Double
        var tags: [String]
        var status: FallbackInventoryTargetStatus

        init(code: String, name: String, source: String, capacity: Int, attributes: [String: String], ratio: Double, tags: [String], status: FallbackInventoryTargetStatus) {
            self.code = code
            self.name = name
            self.source = source
            self.capacity = capacity
            self.attributes = attributes
            self.ratio = ratio
            self.tags = tags
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

        func canMoveTo(_ next: FallbackInventoryTargetStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == FallbackInventoryTargetStatus.rejected || next == FallbackInventoryTargetStatus.withdrawn
            case .rejected:
                return next == FallbackInventoryTargetStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackInventoryTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback inventory target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback inventory target") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
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

        func projectedVolume() -> Double {
            return (ratio * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> FallbackInventoryTarget {
            return FallbackInventoryTarget(
                code: code,
                name: name,
                source: source,
                capacity: capacity,
                attributes: attributes,
                ratio: ratio,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a fallback inventory target in status proposed.
    static func newFallbackInventoryTarget(_ code: String, name: String) -> FallbackInventoryTarget {
        return FallbackInventoryTarget(
            code: code,
            name: name,
            source: "",
            capacity: 0,
            attributes: [:],
            ratio: 0.0,
            tags: [],
            status: FallbackInventoryTargetStatus.proposed
        )
    }
}
