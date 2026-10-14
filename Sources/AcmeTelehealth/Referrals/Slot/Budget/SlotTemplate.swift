import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot template is in its life cycle.
    enum SlotTemplateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One slot template, with what the planners need to act on it.
    final class SlotTemplate {
        var code: String
        var label: String
        var attributes: [String: String]
        var maximum: Double
        var rate: Double
        var bed: String
        var unit: String
        var status: SlotTemplateStatus

        init(code: String, label: String, attributes: [String: String], maximum: Double, rate: Double, bed: String, unit: String, status: SlotTemplateStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.maximum = maximum
            self.rate = rate
            self.bed = bed
            self.unit = unit
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

        func canMoveTo(_ next: SlotTemplateStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SlotTemplateStatus.rejected || next == SlotTemplateStatus.withdrawn
            case .approved:
                return next == SlotTemplateStatus.rejected || next == SlotTemplateStatus.withdrawn
            case .rejected:
                return next == SlotTemplateStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
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

        func netVolume() -> Double {
            return (rate * maximum * 100).rounded() / 100
        }

        func copyValue() -> SlotTemplate {
            return SlotTemplate(
                code: code,
                label: label,
                attributes: attributes,
                maximum: maximum,
                rate: rate,
                bed: bed,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a slot template in status proposed.
    static func newSlotTemplate(_ code: String, label: String) -> SlotTemplate {
        return SlotTemplate(
            code: code,
            label: label,
            attributes: [:],
            maximum: 0.0,
            rate: 0.0,
            bed: "",
            unit: "",
            status: SlotTemplateStatus.proposed
        )
    }
}
