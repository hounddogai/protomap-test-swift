import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach plan is in its life cycle.
    enum OutreachPlanStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a outreach plan and its current status.
    final class OutreachPlan {
        var code: String
        var name: String
        var notes: String
        var bed: String
        var batchSize: Int
        var segment: String
        var windowDays: Int
        var status: OutreachPlanStatus

        init(code: String, name: String, notes: String, bed: String, batchSize: Int, segment: String, windowDays: Int, status: OutreachPlanStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.bed = bed
            self.batchSize = batchSize
            self.segment = segment
            self.windowDays = windowDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OutreachPlanStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == OutreachPlanStatus.revoked || next == OutreachPlanStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: OutreachPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedVolume() -> Double {
            return (Double(batchSize) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> OutreachPlan {
            return OutreachPlan(
                code: code,
                name: name,
                notes: notes,
                bed: bed,
                batchSize: batchSize,
                segment: segment,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a outreach plan in status requested.
    static func newOutreachPlan(_ code: String, name: String) -> OutreachPlan {
        return OutreachPlan(
            code: code,
            name: name,
            notes: "",
            bed: "",
            batchSize: 0,
            segment: "",
            windowDays: 0,
            status: OutreachPlanStatus.requested
        )
    }
}
