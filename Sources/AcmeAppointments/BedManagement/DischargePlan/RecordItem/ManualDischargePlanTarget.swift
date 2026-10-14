import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual discharge plan target is in its life cycle.
    enum ManualDischargePlanTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a manual discharge plan target and its current status.
    final class ManualDischargePlanTarget {
        var code: String
        var label: String
        var attempts: Int
        var refills: Int
        var country: String
        var updatedAt: Int
        var minimum: Double
        var ratio: Double
        var startsAt: Int
        var status: ManualDischargePlanTargetStatus

        init(code: String, label: String, attempts: Int, refills: Int, country: String, updatedAt: Int, minimum: Double, ratio: Double, startsAt: Int, status: ManualDischargePlanTargetStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.refills = refills
            self.country = country
            self.updatedAt = updatedAt
            self.minimum = minimum
            self.ratio = ratio
            self.startsAt = startsAt
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

        func canMoveTo(_ next: ManualDischargePlanTargetStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ManualDischargePlanTargetStatus.resolved || next == ManualDischargePlanTargetStatus.reopened
            case .resolved:
                return next == ManualDischargePlanTargetStatus.reopened || next == ManualDischargePlanTargetStatus.archived
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

        func moveTo(_ next: ManualDischargePlanTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual discharge plan target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("manual discharge plan target") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(updatedAt) + ratio) * 100).rounded() / 100
        }

        func copyValue() -> ManualDischargePlanTarget {
            return ManualDischargePlanTarget(
                code: code,
                label: label,
                attempts: attempts,
                refills: refills,
                country: country,
                updatedAt: updatedAt,
                minimum: minimum,
                ratio: ratio,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a manual discharge plan target in status open.
    static func newManualDischargePlanTarget(_ code: String, label: String) -> ManualDischargePlanTarget {
        return ManualDischargePlanTarget(
            code: code,
            label: label,
            attempts: 0,
            refills: 0,
            country: "",
            updatedAt: 0,
            minimum: 0.0,
            ratio: 0.0,
            startsAt: 0,
            status: ManualDischargePlanTargetStatus.`open`
        )
    }
}
