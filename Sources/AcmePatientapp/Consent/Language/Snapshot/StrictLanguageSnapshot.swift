import AcmePlatform
import Foundation

extension Consent {
    /// Where a strict language snapshot is in its life cycle.
    enum StrictLanguageSnapshotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A strict language snapshot. Its code is unique within a tenant.
    final class StrictLanguageSnapshot {
        var code: String
        var label: String
        var ceiling: Double
        var active: Bool
        var allergy: String
        var segment: String
        var channel: String
        var facility: String
        var category: String
        var status: StrictLanguageSnapshotStatus

        init(code: String, label: String, ceiling: Double, active: Bool, allergy: String, segment: String, channel: String, facility: String, category: String, status: StrictLanguageSnapshotStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.active = active
            self.allergy = allergy
            self.segment = segment
            self.channel = channel
            self.facility = facility
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictLanguageSnapshotStatus) -> Bool {
            switch status {
            case .created:
                return next == StrictLanguageSnapshotStatus.published
            case .validated:
                return next == StrictLanguageSnapshotStatus.published || next == StrictLanguageSnapshotStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: StrictLanguageSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict language snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> StrictLanguageSnapshot {
            return StrictLanguageSnapshot(
                code: code,
                label: label,
                ceiling: ceiling,
                active: active,
                allergy: allergy,
                segment: segment,
                channel: channel,
                facility: facility,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a strict language snapshot in status created.
    static func newStrictLanguageSnapshot(_ code: String, label: String) -> StrictLanguageSnapshot {
        return StrictLanguageSnapshot(
            code: code,
            label: label,
            ceiling: 0.0,
            active: false,
            allergy: "",
            segment: "",
            channel: "",
            facility: "",
            category: "",
            status: StrictLanguageSnapshotStatus.created
        )
    }
}
