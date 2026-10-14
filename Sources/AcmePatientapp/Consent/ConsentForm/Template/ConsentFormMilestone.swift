import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form milestone is in its life cycle.
    enum ConsentFormMilestoneStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A consent form milestone as the consent form team keeps it.
    final class ConsentFormMilestone {
        var code: String
        var name: String
        var ownerID: String
        var unit: String
        var payer: String
        var minimum: Double
        var visible: Bool
        var durationMinutes: Int
        var ward: String
        var active: Bool
        var status: ConsentFormMilestoneStatus

        init(code: String, name: String, ownerID: String, unit: String, payer: String, minimum: Double, visible: Bool, durationMinutes: Int, ward: String, active: Bool, status: ConsentFormMilestoneStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.unit = unit
            self.payer = payer
            self.minimum = minimum
            self.visible = visible
            self.durationMinutes = durationMinutes
            self.ward = ward
            self.active = active
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

        func canMoveTo(_ next: ConsentFormMilestoneStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
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
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ConsentFormMilestoneStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("consent form milestone") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(durationMinutes) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormMilestone {
            return ConsentFormMilestone(
                code: code,
                name: name,
                ownerID: ownerID,
                unit: unit,
                payer: payer,
                minimum: minimum,
                visible: visible,
                durationMinutes: durationMinutes,
                ward: ward,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a consent form milestone in status new.
    static func newConsentFormMilestone(_ code: String, name: String) -> ConsentFormMilestone {
        return ConsentFormMilestone(
            code: code,
            name: name,
            ownerID: "",
            unit: "",
            payer: "",
            minimum: 0.0,
            visible: false,
            durationMinutes: 0,
            ward: "",
            active: false,
            status: ConsentFormMilestoneStatus.new
        )
    }
}
