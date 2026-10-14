import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory preference is in its life cycle.
    enum InventoryPreferenceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a inventory preference and its current status.
    final class InventoryPreference {
        var code: String
        var name: String
        var startsAt: Int
        var channel: String
        var payer: String
        var bed: String
        var attempts: Int
        var attributes: [String: String]
        var minimum: Double
        var floorValue: Double
        var status: InventoryPreferenceStatus

        init(code: String, name: String, startsAt: Int, channel: String, payer: String, bed: String, attempts: Int, attributes: [String: String], minimum: Double, floorValue: Double, status: InventoryPreferenceStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.channel = channel
            self.payer = payer
            self.bed = bed
            self.attempts = attempts
            self.attributes = attributes
            self.minimum = minimum
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InventoryPreferenceStatus) -> Bool {
            switch status {
            case .draft:
                return next == InventoryPreferenceStatus.suspended
            case .pending:
                return next == InventoryPreferenceStatus.suspended || next == InventoryPreferenceStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: InventoryPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
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
            return ((Double(attempts) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> InventoryPreference {
            return InventoryPreference(
                code: code,
                name: name,
                startsAt: startsAt,
                channel: channel,
                payer: payer,
                bed: bed,
                attempts: attempts,
                attributes: attributes,
                minimum: minimum,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a inventory preference in status draft.
    static func newInventoryPreference(_ code: String, name: String) -> InventoryPreference {
        return InventoryPreference(
            code: code,
            name: name,
            startsAt: 0,
            channel: "",
            payer: "",
            bed: "",
            attempts: 0,
            attributes: [:],
            minimum: 0.0,
            floorValue: 0.0,
            status: InventoryPreferenceStatus.draft
        )
    }
}
