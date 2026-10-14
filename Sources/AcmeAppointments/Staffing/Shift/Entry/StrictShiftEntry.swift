import AcmePlatform
import Foundation

extension Staffing {
    /// Where a strict shift entry is in its life cycle.
    enum StrictShiftEntryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A strict shift entry. Its code is unique within a tenant.
    final class StrictShiftEntry {
        var code: String
        var name: String
        var sequence: Int
        var endsAt: Int
        var attributes: [String: String]
        var floorValue: Double
        var ownerID: String
        var encounterID: String
        var cost: Double
        var status: StrictShiftEntryStatus

        init(code: String, name: String, sequence: Int, endsAt: Int, attributes: [String: String], floorValue: Double, ownerID: String, encounterID: String, cost: Double, status: StrictShiftEntryStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.endsAt = endsAt
            self.attributes = attributes
            self.floorValue = floorValue
            self.ownerID = ownerID
            self.encounterID = encounterID
            self.cost = cost
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

        func canMoveTo(_ next: StrictShiftEntryStatus) -> Bool {
            switch status {
            case .draft:
                return next == StrictShiftEntryStatus.pending || next == StrictShiftEntryStatus.suspended
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == StrictShiftEntryStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictShiftEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict shift entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
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

        func adjustedTotal() -> Double {
            return ((Double(sequence) - cost) * 100).rounded() / 100
        }

        func copyValue() -> StrictShiftEntry {
            return StrictShiftEntry(
                code: code,
                name: name,
                sequence: sequence,
                endsAt: endsAt,
                attributes: attributes,
                floorValue: floorValue,
                ownerID: ownerID,
                encounterID: encounterID,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict shift entry in status draft.
    static func newStrictShiftEntry(_ code: String, name: String) -> StrictShiftEntry {
        return StrictShiftEntry(
            code: code,
            name: name,
            sequence: 0,
            endsAt: 0,
            attributes: [:],
            floorValue: 0.0,
            ownerID: "",
            encounterID: "",
            cost: 0.0,
            status: StrictShiftEntryStatus.draft
        )
    }
}
