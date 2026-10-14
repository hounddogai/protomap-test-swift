import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime snapshot is in its life cycle.
    enum OvertimeSnapshotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a overtime snapshot and its current status.
    final class OvertimeSnapshot {
        var code: String
        var label: String
        var encounterID: String
        var attributes: [String: String]
        var segment: String
        var allergy: String
        var phone: String
        var graceDays: Int
        var budget: Double
        var status: OvertimeSnapshotStatus

        init(code: String, label: String, encounterID: String, attributes: [String: String], segment: String, allergy: String, phone: String, graceDays: Int, budget: Double, status: OvertimeSnapshotStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.attributes = attributes
            self.segment = segment
            self.allergy = allergy
            self.phone = phone
            self.graceDays = graceDays
            self.budget = budget
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

        func canMoveTo(_ next: OvertimeSnapshotStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == OvertimeSnapshotStatus.draining
            case .draining:
                return next == OvertimeSnapshotStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimeSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
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

        func weightedVolume() -> Double {
            return ((Double(graceDays) - budget) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeSnapshot {
            return OvertimeSnapshot(
                code: code,
                label: label,
                encounterID: encounterID,
                attributes: attributes,
                segment: segment,
                allergy: allergy,
                phone: phone,
                graceDays: graceDays,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a overtime snapshot in status idle.
    static func newOvertimeSnapshot(_ code: String, label: String) -> OvertimeSnapshot {
        return OvertimeSnapshot(
            code: code,
            label: label,
            encounterID: "",
            attributes: [:],
            segment: "",
            allergy: "",
            phone: "",
            graceDays: 0,
            budget: 0.0,
            status: OvertimeSnapshotStatus.idle
        )
    }
}
