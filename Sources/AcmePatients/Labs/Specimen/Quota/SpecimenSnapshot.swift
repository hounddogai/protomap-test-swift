import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen snapshot is in its life cycle.
    enum SpecimenSnapshotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A specimen snapshot. Its code is unique within a tenant.
    final class SpecimenSnapshot {
        var code: String
        var title: String
        var notes: String
        var active: Bool
        var currency: String
        var tags: [String]
        var batchSize: Int
        var unit: String
        var status: SpecimenSnapshotStatus

        init(code: String, title: String, notes: String, active: Bool, currency: String, tags: [String], batchSize: Int, unit: String, status: SpecimenSnapshotStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.active = active
            self.currency = currency
            self.tags = tags
            self.batchSize = batchSize
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

        func canMoveTo(_ next: SpecimenSnapshotStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == SpecimenSnapshotStatus.rejected
            case .rejected:
                return next == SpecimenSnapshotStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
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
            return Double(batchSize)
        }

        func copyValue() -> SpecimenSnapshot {
            return SpecimenSnapshot(
                code: code,
                title: title,
                notes: notes,
                active: active,
                currency: currency,
                tags: tags,
                batchSize: batchSize,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a specimen snapshot in status proposed.
    static func newSpecimenSnapshot(_ code: String, title: String) -> SpecimenSnapshot {
        return SpecimenSnapshot(
            code: code,
            title: title,
            notes: "",
            active: false,
            currency: "",
            tags: [],
            batchSize: 0,
            unit: "",
            status: SpecimenSnapshotStatus.proposed
        )
    }
}
