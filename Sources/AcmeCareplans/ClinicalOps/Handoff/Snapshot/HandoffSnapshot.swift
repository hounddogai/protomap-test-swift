import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff snapshot is in its life cycle.
    enum HandoffSnapshotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a handoff snapshot and its current status.
    final class HandoffSnapshot {
        var code: String
        var name: String
        var diagnosisCode: String
        var currency: String
        var active: Bool
        var floorValue: Double
        var retries: Int
        var minimum: Double
        var approved: Bool
        var tags: [String]
        var status: HandoffSnapshotStatus

        init(code: String, name: String, diagnosisCode: String, currency: String, active: Bool, floorValue: Double, retries: Int, minimum: Double, approved: Bool, tags: [String], status: HandoffSnapshotStatus) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.currency = currency
            self.active = active
            self.floorValue = floorValue
            self.retries = retries
            self.minimum = minimum
            self.approved = approved
            self.tags = tags
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

        func canMoveTo(_ next: HandoffSnapshotStatus) -> Bool {
            switch status {
            case .proposed:
                return next == HandoffSnapshotStatus.withdrawn
            case .approved:
                return next == HandoffSnapshotStatus.rejected || next == HandoffSnapshotStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: HandoffSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveLoad() -> Double {
            return ((Double(retries) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> HandoffSnapshot {
            return HandoffSnapshot(
                code: code,
                name: name,
                diagnosisCode: diagnosisCode,
                currency: currency,
                active: active,
                floorValue: floorValue,
                retries: retries,
                minimum: minimum,
                approved: approved,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a handoff snapshot in status proposed.
    static func newHandoffSnapshot(_ code: String, name: String) -> HandoffSnapshot {
        return HandoffSnapshot(
            code: code,
            name: name,
            diagnosisCode: "",
            currency: "",
            active: false,
            floorValue: 0.0,
            retries: 0,
            minimum: 0.0,
            approved: false,
            tags: [],
            status: HandoffSnapshotStatus.proposed
        )
    }
}
