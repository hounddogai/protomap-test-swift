import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift template is in its life cycle.
    enum ShiftTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A shift template. Its code is unique within a tenant.
    final class ShiftTemplate {
        var code: String
        var title: String
        var floorValue: Double
        var reviewer: String
        var ward: String
        var attempts: Int
        var priority: Int
        var allergy: String
        var segment: String
        var cost: Double
        var active: Bool
        var status: ShiftTemplateStatus

        init(code: String, title: String, floorValue: Double, reviewer: String, ward: String, attempts: Int, priority: Int, allergy: String, segment: String, cost: Double, active: Bool, status: ShiftTemplateStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.reviewer = reviewer
            self.ward = ward
            self.attempts = attempts
            self.priority = priority
            self.allergy = allergy
            self.segment = segment
            self.cost = cost
            self.active = active
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

        func canMoveTo(_ next: ShiftTemplateStatus) -> Bool {
            switch status {
            case .idle:
                return next == ShiftTemplateStatus.warming || next == ShiftTemplateStatus.stopped
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ShiftTemplateStatus.draining || next == ShiftTemplateStatus.stopped
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

        func moveTo(_ next: ShiftTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedValue() -> Double {
            return (Double(priority) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> ShiftTemplate {
            return ShiftTemplate(
                code: code,
                title: title,
                floorValue: floorValue,
                reviewer: reviewer,
                ward: ward,
                attempts: attempts,
                priority: priority,
                allergy: allergy,
                segment: segment,
                cost: cost,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a shift template in status idle.
    static func newShiftTemplate(_ code: String, title: String) -> ShiftTemplate {
        return ShiftTemplate(
            code: code,
            title: title,
            floorValue: 0.0,
            reviewer: "",
            ward: "",
            attempts: 0,
            priority: 0,
            allergy: "",
            segment: "",
            cost: 0.0,
            active: false,
            status: ShiftTemplateStatus.idle
        )
    }
}
