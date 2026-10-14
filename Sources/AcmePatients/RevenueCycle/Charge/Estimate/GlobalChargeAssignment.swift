import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a global charge assignment is in its life cycle.
    enum GlobalChargeAssignmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a global charge assignment and its current status.
    final class GlobalChargeAssignment {
        var code: String
        var title: String
        var specialty: String
        var patientRef: String
        var discount: Double
        var region: String
        var windowDays: Int
        var externalRef: String
        var status: GlobalChargeAssignmentStatus

        init(code: String, title: String, specialty: String, patientRef: String, discount: Double, region: String, windowDays: Int, externalRef: String, status: GlobalChargeAssignmentStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.patientRef = patientRef
            self.discount = discount
            self.region = region
            self.windowDays = windowDays
            self.externalRef = externalRef
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

        func canMoveTo(_ next: GlobalChargeAssignmentStatus) -> Bool {
            switch status {
            case .`open`:
                return next == GlobalChargeAssignmentStatus.reopened
            case .inReview:
                return next == GlobalChargeAssignmentStatus.resolved
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == GlobalChargeAssignmentStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalChargeAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global charge assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedExposure() -> Double {
            return (discount * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> GlobalChargeAssignment {
            return GlobalChargeAssignment(
                code: code,
                title: title,
                specialty: specialty,
                patientRef: patientRef,
                discount: discount,
                region: region,
                windowDays: windowDays,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a global charge assignment in status open.
    static func newGlobalChargeAssignment(_ code: String, title: String) -> GlobalChargeAssignment {
        return GlobalChargeAssignment(
            code: code,
            title: title,
            specialty: "",
            patientRef: "",
            discount: 0.0,
            region: "",
            windowDays: 0,
            externalRef: "",
            status: GlobalChargeAssignmentStatus.`open`
        )
    }
}
