import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a default discharge plan item is in its life cycle.
    enum DefaultDischargePlanItemStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One default discharge plan item, with what the planners need to act on it.
    final class DefaultDischargePlanItem {
        var code: String
        var name: String
        var allergy: String
        var tags: [String]
        var ratio: Double
        var retries: Int
        var quantity: Int
        var windowDays: Int
        var label: String
        var phone: String
        var status: DefaultDischargePlanItemStatus

        init(code: String, name: String, allergy: String, tags: [String], ratio: Double, retries: Int, quantity: Int, windowDays: Int, label: String, phone: String, status: DefaultDischargePlanItemStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.tags = tags
            self.ratio = ratio
            self.retries = retries
            self.quantity = quantity
            self.windowDays = windowDays
            self.label = label
            self.phone = phone
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

        func canMoveTo(_ next: DefaultDischargePlanItemStatus) -> Bool {
            switch status {
            case .idle:
                return next == DefaultDischargePlanItemStatus.warming || next == DefaultDischargePlanItemStatus.ready
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == DefaultDischargePlanItemStatus.draining || next == DefaultDischargePlanItemStatus.stopped
            case .draining:
                return next == DefaultDischargePlanItemStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultDischargePlanItemStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default discharge plan item \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
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

        func netLoad() -> Double {
            return ((Double(retries) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultDischargePlanItem {
            return DefaultDischargePlanItem(
                code: code,
                name: name,
                allergy: allergy,
                tags: tags,
                ratio: ratio,
                retries: retries,
                quantity: quantity,
                windowDays: windowDays,
                label: label,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default discharge plan item in status idle.
    static func newDefaultDischargePlanItem(_ code: String, name: String) -> DefaultDischargePlanItem {
        return DefaultDischargePlanItem(
            code: code,
            name: name,
            allergy: "",
            tags: [],
            ratio: 0.0,
            retries: 0,
            quantity: 0,
            windowDays: 0,
            label: "",
            phone: "",
            status: DefaultDischargePlanItemStatus.idle
        )
    }
}
