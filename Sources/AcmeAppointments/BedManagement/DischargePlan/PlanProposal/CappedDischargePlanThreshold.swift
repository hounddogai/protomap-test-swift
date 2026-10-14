import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a capped discharge plan threshold is in its life cycle.
    enum CappedDischargePlanThresholdStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A capped discharge plan threshold. Its code is unique within a tenant.
    final class CappedDischargePlanThreshold {
        var code: String
        var title: String
        var weight: Double
        var contactEmail: String
        var windowDays: Int
        var pinned: Bool
        var minimum: Double
        var acuity: Int
        var status: CappedDischargePlanThresholdStatus

        init(code: String, title: String, weight: Double, contactEmail: String, windowDays: Int, pinned: Bool, minimum: Double, acuity: Int, status: CappedDischargePlanThresholdStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.contactEmail = contactEmail
            self.windowDays = windowDays
            self.pinned = pinned
            self.minimum = minimum
            self.acuity = acuity
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

        func canMoveTo(_ next: CappedDischargePlanThresholdStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
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
                return next == CappedDischargePlanThresholdStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedDischargePlanThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped discharge plan threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveVolume() -> Double {
            return ((minimum + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> CappedDischargePlanThreshold {
            return CappedDischargePlanThreshold(
                code: code,
                title: title,
                weight: weight,
                contactEmail: contactEmail,
                windowDays: windowDays,
                pinned: pinned,
                minimum: minimum,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped discharge plan threshold in status created.
    static func newCappedDischargePlanThreshold(_ code: String, title: String) -> CappedDischargePlanThreshold {
        return CappedDischargePlanThreshold(
            code: code,
            title: title,
            weight: 0.0,
            contactEmail: "",
            windowDays: 0,
            pinned: false,
            minimum: 0.0,
            acuity: 0,
            status: CappedDischargePlanThresholdStatus.created
        )
    }
}
