import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional disclosure snapshot is in its life cycle.
    enum RegionalDisclosureSnapshotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A regional disclosure snapshot. Its code is unique within a tenant.
    final class RegionalDisclosureSnapshot {
        var code: String
        var title: String
        var phone: String
        var acuity: Int
        var unit: String
        var minimum: Double
        var budget: Double
        var expiresAt: Int
        var patientRef: String
        var status: RegionalDisclosureSnapshotStatus

        init(code: String, title: String, phone: String, acuity: Int, unit: String, minimum: Double, budget: Double, expiresAt: Int, patientRef: String, status: RegionalDisclosureSnapshotStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.acuity = acuity
            self.unit = unit
            self.minimum = minimum
            self.budget = budget
            self.expiresAt = expiresAt
            self.patientRef = patientRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalDisclosureSnapshotStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == RegionalDisclosureSnapshotStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RegionalDisclosureSnapshotStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalDisclosureSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional disclosure snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("regional disclosure snapshot") \(code)"
        }

        func adjustedExposure() -> Double {
            return (Double(acuity) * budget * 100).rounded() / 100
        }

        func copyValue() -> RegionalDisclosureSnapshot {
            return RegionalDisclosureSnapshot(
                code: code,
                title: title,
                phone: phone,
                acuity: acuity,
                unit: unit,
                minimum: minimum,
                budget: budget,
                expiresAt: expiresAt,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a regional disclosure snapshot in status planned.
    static func newRegionalDisclosureSnapshot(_ code: String, title: String) -> RegionalDisclosureSnapshot {
        return RegionalDisclosureSnapshot(
            code: code,
            title: title,
            phone: "",
            acuity: 0,
            unit: "",
            minimum: 0.0,
            budget: 0.0,
            expiresAt: 0,
            patientRef: "",
            status: RegionalDisclosureSnapshotStatus.planned
        )
    }
}
