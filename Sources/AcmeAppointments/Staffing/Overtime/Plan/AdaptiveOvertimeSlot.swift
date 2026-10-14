import AcmePlatform
import Foundation

extension Staffing {
    /// Where a adaptive overtime slot is in its life cycle.
    enum AdaptiveOvertimeSlotStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a adaptive overtime slot and its current status.
    final class AdaptiveOvertimeSlot {
        var code: String
        var name: String
        var currency: String
        var startsAt: Int
        var updatedAt: Int
        var category: String
        var limit: Int
        var retries: Int
        var patientRef: String
        var active: Bool
        var label: String
        var status: AdaptiveOvertimeSlotStatus

        init(code: String, name: String, currency: String, startsAt: Int, updatedAt: Int, category: String, limit: Int, retries: Int, patientRef: String, active: Bool, label: String, status: AdaptiveOvertimeSlotStatus) {
            self.code = code
            self.name = name
            self.currency = currency
            self.startsAt = startsAt
            self.updatedAt = updatedAt
            self.category = category
            self.limit = limit
            self.retries = retries
            self.patientRef = patientRef
            self.active = active
            self.label = label
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveOvertimeSlotStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == AdaptiveOvertimeSlotStatus.reopened
            case .resolved:
                return next == AdaptiveOvertimeSlotStatus.reopened || next == AdaptiveOvertimeSlotStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: AdaptiveOvertimeSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive overtime slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func weightedExposure() -> Double {
            return (Double(limit) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveOvertimeSlot {
            return AdaptiveOvertimeSlot(
                code: code,
                name: name,
                currency: currency,
                startsAt: startsAt,
                updatedAt: updatedAt,
                category: category,
                limit: limit,
                retries: retries,
                patientRef: patientRef,
                active: active,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a adaptive overtime slot in status open.
    static func newAdaptiveOvertimeSlot(_ code: String, name: String) -> AdaptiveOvertimeSlot {
        return AdaptiveOvertimeSlot(
            code: code,
            name: name,
            currency: "",
            startsAt: 0,
            updatedAt: 0,
            category: "",
            limit: 0,
            retries: 0,
            patientRef: "",
            active: false,
            label: "",
            status: AdaptiveOvertimeSlotStatus.`open`
        )
    }
}
