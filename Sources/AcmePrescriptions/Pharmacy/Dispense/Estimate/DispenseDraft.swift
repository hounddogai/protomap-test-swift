import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense draft is in its life cycle.
    enum DispenseDraftStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A dispense draft. Its code is unique within a tenant.
    final class DispenseDraft {
        var code: String
        var label: String
        var channel: String
        var notes: String
        var region: String
        var copay: Double
        var retries: Int
        var status: DispenseDraftStatus

        init(code: String, label: String, channel: String, notes: String, region: String, copay: Double, retries: Int, status: DispenseDraftStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.notes = notes
            self.region = region
            self.copay = copay
            self.retries = retries
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

        func canMoveTo(_ next: DispenseDraftStatus) -> Bool {
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
                return next == DispenseDraftStatus.rejected
            case .rejected:
                return next == DispenseDraftStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispenseDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedValue() -> Double {
            return ((copay + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> DispenseDraft {
            return DispenseDraft(
                code: code,
                label: label,
                channel: channel,
                notes: notes,
                region: region,
                copay: copay,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a dispense draft in status proposed.
    static func newDispenseDraft(_ code: String, label: String) -> DispenseDraft {
        return DispenseDraft(
            code: code,
            label: label,
            channel: "",
            notes: "",
            region: "",
            copay: 0.0,
            retries: 0,
            status: DispenseDraftStatus.proposed
        )
    }
}
