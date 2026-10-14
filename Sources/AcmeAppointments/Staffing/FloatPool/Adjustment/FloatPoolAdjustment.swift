import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool adjustment is in its life cycle.
    enum FloatPoolAdjustmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A float pool adjustment. Its code is unique within a tenant.
    final class FloatPoolAdjustment {
        var code: String
        var label: String
        var approved: Bool
        var notes: String
        var region: String
        var margin: Double
        var status: FloatPoolAdjustmentStatus

        init(code: String, label: String, approved: Bool, notes: String, region: String, margin: Double, status: FloatPoolAdjustmentStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.notes = notes
            self.region = region
            self.margin = margin
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

        func canMoveTo(_ next: FloatPoolAdjustmentStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: FloatPoolAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("float pool adjustment") \(code)"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> FloatPoolAdjustment {
            return FloatPoolAdjustment(
                code: code,
                label: label,
                approved: approved,
                notes: notes,
                region: region,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a float pool adjustment in status created.
    static func newFloatPoolAdjustment(_ code: String, label: String) -> FloatPoolAdjustment {
        return FloatPoolAdjustment(
            code: code,
            label: label,
            approved: false,
            notes: "",
            region: "",
            margin: 0.0,
            status: FloatPoolAdjustmentStatus.created
        )
    }
}
