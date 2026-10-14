import AcmePlatform
import Foundation

extension Staffing {
    /// Where a strict acuity plan bundle is in its life cycle.
    enum StrictAcuityPlanBundleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a strict acuity plan bundle and its current status.
    final class StrictAcuityPlanBundle {
        var code: String
        var title: String
        var patientRef: String
        var externalRef: String
        var updatedAt: Int
        var approved: Bool
        var ratio: Double
        var revision: Int
        var unit: String
        var status: StrictAcuityPlanBundleStatus

        init(code: String, title: String, patientRef: String, externalRef: String, updatedAt: Int, approved: Bool, ratio: Double, revision: Int, unit: String, status: StrictAcuityPlanBundleStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.externalRef = externalRef
            self.updatedAt = updatedAt
            self.approved = approved
            self.ratio = ratio
            self.revision = revision
            self.unit = unit
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

        func canMoveTo(_ next: StrictAcuityPlanBundleStatus) -> Bool {
            switch status {
            case .new:
                return next == StrictAcuityPlanBundleStatus.running
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == StrictAcuityPlanBundleStatus.done
            case .done:
                return next == StrictAcuityPlanBundleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictAcuityPlanBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict acuity plan bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("strict acuity plan bundle") \(code)"
        }

        func projectedVolume() -> Double {
            return ((ratio + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> StrictAcuityPlanBundle {
            return StrictAcuityPlanBundle(
                code: code,
                title: title,
                patientRef: patientRef,
                externalRef: externalRef,
                updatedAt: updatedAt,
                approved: approved,
                ratio: ratio,
                revision: revision,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a strict acuity plan bundle in status new.
    static func newStrictAcuityPlanBundle(_ code: String, title: String) -> StrictAcuityPlanBundle {
        return StrictAcuityPlanBundle(
            code: code,
            title: title,
            patientRef: "",
            externalRef: "",
            updatedAt: 0,
            approved: false,
            ratio: 0.0,
            revision: 0,
            unit: "",
            status: StrictAcuityPlanBundleStatus.new
        )
    }
}
