import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift threshold is in its life cycle.
    enum ShiftThresholdStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A shift threshold. Its code is unique within a tenant.
    final class ShiftThreshold {
        var code: String
        var name: String
        var weight: Double
        var contactEmail: String
        var externalRef: String
        var region: String
        var unit: String
        var status: ShiftThresholdStatus

        init(code: String, name: String, weight: Double, contactEmail: String, externalRef: String, region: String, unit: String, status: ShiftThresholdStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.contactEmail = contactEmail
            self.externalRef = externalRef
            self.region = region
            self.unit = unit
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

        func canMoveTo(_ next: ShiftThresholdStatus) -> Bool {
            switch status {
            case .draft:
                return next == ShiftThresholdStatus.active
            case .pending:
                return next == ShiftThresholdStatus.active
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ShiftThresholdStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ShiftThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return weight
        }

        func copyValue() -> ShiftThreshold {
            return ShiftThreshold(
                code: code,
                name: name,
                weight: weight,
                contactEmail: contactEmail,
                externalRef: externalRef,
                region: region,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a shift threshold in status draft.
    static func newShiftThreshold(_ code: String, name: String) -> ShiftThreshold {
        return ShiftThreshold(
            code: code,
            name: name,
            weight: 0.0,
            contactEmail: "",
            externalRef: "",
            region: "",
            unit: "",
            status: ShiftThresholdStatus.draft
        )
    }
}
