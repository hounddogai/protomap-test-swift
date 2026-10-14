import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift audit is in its life cycle.
    enum ShiftAuditStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A shift audit. Its code is unique within a tenant.
    final class ShiftAudit {
        var code: String
        var title: String
        var budget: Double
        var phone: String
        var limit: Int
        var cost: Double
        var refills: Int
        var specialty: String
        var label: String
        var status: ShiftAuditStatus

        init(code: String, title: String, budget: Double, phone: String, limit: Int, cost: Double, refills: Int, specialty: String, label: String, status: ShiftAuditStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.phone = phone
            self.limit = limit
            self.cost = cost
            self.refills = refills
            self.specialty = specialty
            self.label = label
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ShiftAuditStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ShiftAuditStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ShiftAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("shift audit") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((budget + cost) * 100).rounded() / 100
        }

        func copyValue() -> ShiftAudit {
            return ShiftAudit(
                code: code,
                title: title,
                budget: budget,
                phone: phone,
                limit: limit,
                cost: cost,
                refills: refills,
                specialty: specialty,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a shift audit in status new.
    static func newShiftAudit(_ code: String, title: String) -> ShiftAudit {
        return ShiftAudit(
            code: code,
            title: title,
            budget: 0.0,
            phone: "",
            limit: 0,
            cost: 0.0,
            refills: 0,
            specialty: "",
            label: "",
            status: ShiftAuditStatus.new
        )
    }
}
