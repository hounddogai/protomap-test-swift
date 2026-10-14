import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a global statement estimate is in its life cycle.
    enum GlobalStatementEstimateStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A global statement estimate as the statement team keeps it.
    final class GlobalStatementEstimate {
        var code: String
        var label: String
        var retries: Int
        var approved: Bool
        var minimum: Double
        var durationMinutes: Int
        var clinicianID: String
        var active: Bool
        var patientRef: String
        var refills: Int
        var createdAt: Int
        var status: GlobalStatementEstimateStatus

        init(code: String, label: String, retries: Int, approved: Bool, minimum: Double, durationMinutes: Int, clinicianID: String, active: Bool, patientRef: String, refills: Int, createdAt: Int, status: GlobalStatementEstimateStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.approved = approved
            self.minimum = minimum
            self.durationMinutes = durationMinutes
            self.clinicianID = clinicianID
            self.active = active
            self.patientRef = patientRef
            self.refills = refills
            self.createdAt = createdAt
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

        func canMoveTo(_ next: GlobalStatementEstimateStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == GlobalStatementEstimateStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: GlobalStatementEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global statement estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netExposure() -> Double {
            return ((Double(retries) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> GlobalStatementEstimate {
            return GlobalStatementEstimate(
                code: code,
                label: label,
                retries: retries,
                approved: approved,
                minimum: minimum,
                durationMinutes: durationMinutes,
                clinicianID: clinicianID,
                active: active,
                patientRef: patientRef,
                refills: refills,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global statement estimate in status created.
    static func newGlobalStatementEstimate(_ code: String, label: String) -> GlobalStatementEstimate {
        return GlobalStatementEstimate(
            code: code,
            label: label,
            retries: 0,
            approved: false,
            minimum: 0.0,
            durationMinutes: 0,
            clinicianID: "",
            active: false,
            patientRef: "",
            refills: 0,
            createdAt: 0,
            status: GlobalStatementEstimateStatus.created
        )
    }
}
