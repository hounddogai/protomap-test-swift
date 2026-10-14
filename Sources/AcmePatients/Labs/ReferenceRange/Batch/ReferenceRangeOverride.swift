import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range override is in its life cycle.
    enum ReferenceRangeOverrideStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A reference range override. Its code is unique within a tenant.
    final class ReferenceRangeOverride {
        var code: String
        var label: String
        var floorValue: Double
        var dosageMg: Double
        var name: String
        var refills: Int
        var timezone: String
        var description: String
        var approved: Bool
        var channel: String
        var status: ReferenceRangeOverrideStatus

        init(code: String, label: String, floorValue: Double, dosageMg: Double, name: String, refills: Int, timezone: String, description: String, approved: Bool, channel: String, status: ReferenceRangeOverrideStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.dosageMg = dosageMg
            self.name = name
            self.refills = refills
            self.timezone = timezone
            self.description = description
            self.approved = approved
            self.channel = channel
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

        func canMoveTo(_ next: ReferenceRangeOverrideStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ReferenceRangeOverrideStatus.active
            case .active:
                return next == ReferenceRangeOverrideStatus.suspended
            case .suspended:
                return next == ReferenceRangeOverrideStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveLoad() -> Double {
            return ((floorValue - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeOverride {
            return ReferenceRangeOverride(
                code: code,
                label: label,
                floorValue: floorValue,
                dosageMg: dosageMg,
                name: name,
                refills: refills,
                timezone: timezone,
                description: description,
                approved: approved,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a reference range override in status draft.
    static func newReferenceRangeOverride(_ code: String, label: String) -> ReferenceRangeOverride {
        return ReferenceRangeOverride(
            code: code,
            label: label,
            floorValue: 0.0,
            dosageMg: 0.0,
            name: "",
            refills: 0,
            timezone: "",
            description: "",
            approved: false,
            channel: "",
            status: ReferenceRangeOverrideStatus.draft
        )
    }
}
