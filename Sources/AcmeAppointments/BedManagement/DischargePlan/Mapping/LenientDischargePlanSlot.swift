import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient discharge plan slot is in its life cycle.
    enum LenientDischargePlanSlotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A lenient discharge plan slot as the discharge plan team keeps it.
    final class LenientDischargePlanSlot {
        var code: String
        var label: String
        var capacity: Int
        var segment: String
        var attributes: [String: String]
        var name: String
        var externalRef: String
        var status: LenientDischargePlanSlotStatus

        init(code: String, label: String, capacity: Int, segment: String, attributes: [String: String], name: String, externalRef: String, status: LenientDischargePlanSlotStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.segment = segment
            self.attributes = attributes
            self.name = name
            self.externalRef = externalRef
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

        func canMoveTo(_ next: LenientDischargePlanSlotStatus) -> Bool {
            switch status {
            case .new:
                return next == LenientDischargePlanSlotStatus.running
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == LenientDischargePlanSlotStatus.done || next == LenientDischargePlanSlotStatus.failed
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

        func moveTo(_ next: LenientDischargePlanSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient discharge plan slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func measuredValue() -> Double {
            return Double(capacity)
        }

        func copyValue() -> LenientDischargePlanSlot {
            return LenientDischargePlanSlot(
                code: code,
                label: label,
                capacity: capacity,
                segment: segment,
                attributes: attributes,
                name: name,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a lenient discharge plan slot in status new.
    static func newLenientDischargePlanSlot(_ code: String, label: String) -> LenientDischargePlanSlot {
        return LenientDischargePlanSlot(
            code: code,
            label: label,
            capacity: 0,
            segment: "",
            attributes: [:],
            name: "",
            externalRef: "",
            status: LenientDischargePlanSlotStatus.new
        )
    }
}
