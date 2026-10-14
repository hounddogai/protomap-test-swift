import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a weighted task override is in its life cycle.
    enum WeightedTaskOverrideStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One weighted task override, with what the planners need to act on it.
    final class WeightedTaskOverride {
        var code: String
        var name: String
        var tags: [String]
        var segment: String
        var country: String
        var visible: Bool
        var quantity: Int
        var status: WeightedTaskOverrideStatus

        init(code: String, name: String, tags: [String], segment: String, country: String, visible: Bool, quantity: Int, status: WeightedTaskOverrideStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.segment = segment
            self.country = country
            self.visible = visible
            self.quantity = quantity
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

        func canMoveTo(_ next: WeightedTaskOverrideStatus) -> Bool {
            switch status {
            case .created:
                return next == WeightedTaskOverrideStatus.retired
            case .validated:
                return next == WeightedTaskOverrideStatus.retired
            case .published:
                return next == WeightedTaskOverrideStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedTaskOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted task override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> WeightedTaskOverride {
            return WeightedTaskOverride(
                code: code,
                name: name,
                tags: tags,
                segment: segment,
                country: country,
                visible: visible,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a weighted task override in status created.
    static func newWeightedTaskOverride(_ code: String, name: String) -> WeightedTaskOverride {
        return WeightedTaskOverride(
            code: code,
            name: name,
            tags: [],
            segment: "",
            country: "",
            visible: false,
            quantity: 0,
            status: WeightedTaskOverrideStatus.created
        )
    }
}
