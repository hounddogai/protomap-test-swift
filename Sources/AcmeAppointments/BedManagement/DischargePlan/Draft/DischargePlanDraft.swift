import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan draft is in its life cycle.
    enum DischargePlanDraftStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A discharge plan draft as the discharge plan team keeps it.
    final class DischargePlanDraft {
        var code: String
        var title: String
        var updatedAt: Int
        var facility: String
        var rate: Double
        var visitMinutes: Int
        var status: DischargePlanDraftStatus

        init(code: String, title: String, updatedAt: Int, facility: String, rate: Double, visitMinutes: Int, status: DischargePlanDraftStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.facility = facility
            self.rate = rate
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: DischargePlanDraftStatus) -> Bool {
            switch status {
            case .idle:
                return next == DischargePlanDraftStatus.ready || next == DischargePlanDraftStatus.draining
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DischargePlanDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedExposure() -> Double {
            return ((Double(updatedAt) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanDraft {
            return DischargePlanDraft(
                code: code,
                title: title,
                updatedAt: updatedAt,
                facility: facility,
                rate: rate,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a discharge plan draft in status idle.
    static func newDischargePlanDraft(_ code: String, title: String) -> DischargePlanDraft {
        return DischargePlanDraft(
            code: code,
            title: title,
            updatedAt: 0,
            facility: "",
            rate: 0.0,
            visitMinutes: 0,
            status: DischargePlanDraftStatus.idle
        )
    }
}
