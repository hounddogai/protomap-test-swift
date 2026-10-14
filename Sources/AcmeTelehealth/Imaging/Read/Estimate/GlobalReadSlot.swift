import AcmePlatform
import Foundation

extension Imaging {
    /// Where a global read slot is in its life cycle.
    enum GlobalReadSlotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One global read slot, with what the planners need to act on it.
    final class GlobalReadSlot {
        var code: String
        var name: String
        var visitMinutes: Int
        var phone: String
        var ceiling: Double
        var currency: String
        var attributes: [String: String]
        var segment: String
        var minimum: Double
        var description: String
        var discount: Double
        var status: GlobalReadSlotStatus

        init(code: String, name: String, visitMinutes: Int, phone: String, ceiling: Double, currency: String, attributes: [String: String], segment: String, minimum: Double, description: String, discount: Double, status: GlobalReadSlotStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.phone = phone
            self.ceiling = ceiling
            self.currency = currency
            self.attributes = attributes
            self.segment = segment
            self.minimum = minimum
            self.description = description
            self.discount = discount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalReadSlotStatus) -> Bool {
            switch status {
            case .new:
                return next == GlobalReadSlotStatus.running || next == GlobalReadSlotStatus.failed
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == GlobalReadSlotStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: GlobalReadSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global read slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
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

        func effectiveTotal() -> Double {
            return (ceiling * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> GlobalReadSlot {
            return GlobalReadSlot(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                phone: phone,
                ceiling: ceiling,
                currency: currency,
                attributes: attributes,
                segment: segment,
                minimum: minimum,
                description: description,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a global read slot in status new.
    static func newGlobalReadSlot(_ code: String, name: String) -> GlobalReadSlot {
        return GlobalReadSlot(
            code: code,
            name: name,
            visitMinutes: 0,
            phone: "",
            ceiling: 0.0,
            currency: "",
            attributes: [:],
            segment: "",
            minimum: 0.0,
            description: "",
            discount: 0.0,
            status: GlobalReadSlotStatus.new
        )
    }
}
