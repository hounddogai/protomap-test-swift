import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial bundle is in its life cycle.
    enum DenialBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One denial bundle, with what the planners need to act on it.
    final class DenialBundle {
        var code: String
        var name: String
        var allergy: String
        var quantity: Int
        var minimum: Double
        var attributes: [String: String]
        var priority: Int
        var status: DenialBundleStatus

        init(code: String, name: String, allergy: String, quantity: Int, minimum: Double, attributes: [String: String], priority: Int, status: DenialBundleStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.quantity = quantity
            self.minimum = minimum
            self.attributes = attributes
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DenialBundleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == DenialBundleStatus.ready || next == DenialBundleStatus.stopped
            case .ready:
                return next == DenialBundleStatus.draining || next == DenialBundleStatus.stopped
            case .draining:
                return next == DenialBundleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DenialBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("denial bundle") \(code)"
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

        func effectiveExposure() -> Double {
            return ((minimum + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> DenialBundle {
            return DenialBundle(
                code: code,
                name: name,
                allergy: allergy,
                quantity: quantity,
                minimum: minimum,
                attributes: attributes,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a denial bundle in status idle.
    static func newDenialBundle(_ code: String, name: String) -> DenialBundle {
        return DenialBundle(
            code: code,
            name: name,
            allergy: "",
            quantity: 0,
            minimum: 0.0,
            attributes: [:],
            priority: 0,
            status: DenialBundleStatus.idle
        )
    }
}
