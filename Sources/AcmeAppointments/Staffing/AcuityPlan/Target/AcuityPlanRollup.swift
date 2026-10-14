import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan rollup is in its life cycle.
    enum AcuityPlanRollupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A acuity plan rollup as the acuity plan team keeps it.
    final class AcuityPlanRollup {
        var code: String
        var title: String
        var facility: String
        var durationMinutes: Int
        var discount: Double
        var externalRef: String
        var notes: String
        var ownerID: String
        var revision: Int
        var locale: String
        var status: AcuityPlanRollupStatus

        init(code: String, title: String, facility: String, durationMinutes: Int, discount: Double, externalRef: String, notes: String, ownerID: String, revision: Int, locale: String, status: AcuityPlanRollupStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.durationMinutes = durationMinutes
            self.discount = discount
            self.externalRef = externalRef
            self.notes = notes
            self.ownerID = ownerID
            self.revision = revision
            self.locale = locale
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

        func canMoveTo(_ next: AcuityPlanRollupStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == AcuityPlanRollupStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == AcuityPlanRollupStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AcuityPlanRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("acuity plan rollup") \(code)"
        }

        func adjustedExposure() -> Double {
            return (Double(revision) * discount * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanRollup {
            return AcuityPlanRollup(
                code: code,
                title: title,
                facility: facility,
                durationMinutes: durationMinutes,
                discount: discount,
                externalRef: externalRef,
                notes: notes,
                ownerID: ownerID,
                revision: revision,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a acuity plan rollup in status idle.
    static func newAcuityPlanRollup(_ code: String, title: String) -> AcuityPlanRollup {
        return AcuityPlanRollup(
            code: code,
            title: title,
            facility: "",
            durationMinutes: 0,
            discount: 0.0,
            externalRef: "",
            notes: "",
            ownerID: "",
            revision: 0,
            locale: "",
            status: AcuityPlanRollupStatus.idle
        )
    }
}
