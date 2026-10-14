import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol snapshot is in its life cycle.
    enum CareProtocolSnapshotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a care protocol snapshot and its current status.
    final class CareProtocolSnapshot {
        var code: String
        var name: String
        var startsAt: Int
        var encounterID: String
        var timezone: String
        var budget: Double
        var attributes: [String: String]
        var currency: String
        var status: CareProtocolSnapshotStatus

        init(code: String, name: String, startsAt: Int, encounterID: String, timezone: String, budget: Double, attributes: [String: String], currency: String, status: CareProtocolSnapshotStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.encounterID = encounterID
            self.timezone = timezone
            self.budget = budget
            self.attributes = attributes
            self.currency = currency
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

        func canMoveTo(_ next: CareProtocolSnapshotStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == CareProtocolSnapshotStatus.draining || next == CareProtocolSnapshotStatus.stopped
            case .ready:
                return next == CareProtocolSnapshotStatus.draining || next == CareProtocolSnapshotStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: CareProtocolSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("care protocol snapshot") \(code)"
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

        func effectiveValue() -> Double {
            return ((Double(startsAt) + budget) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolSnapshot {
            return CareProtocolSnapshot(
                code: code,
                name: name,
                startsAt: startsAt,
                encounterID: encounterID,
                timezone: timezone,
                budget: budget,
                attributes: attributes,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care protocol snapshot in status idle.
    static func newCareProtocolSnapshot(_ code: String, name: String) -> CareProtocolSnapshot {
        return CareProtocolSnapshot(
            code: code,
            name: name,
            startsAt: 0,
            encounterID: "",
            timezone: "",
            budget: 0.0,
            attributes: [:],
            currency: "",
            status: CareProtocolSnapshotStatus.idle
        )
    }
}
