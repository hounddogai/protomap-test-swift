import AcmePlatform
import Foundation

extension Staffing {
    /// Where a manual acuity plan draft is in its life cycle.
    enum ManualAcuityPlanDraftStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A manual acuity plan draft as the acuity plan team keeps it.
    final class ManualAcuityPlanDraft {
        var code: String
        var name: String
        var payer: String
        var attempts: Int
        var threshold: Double
        var windowDays: Int
        var dosageMg: Double
        var status: ManualAcuityPlanDraftStatus

        init(code: String, name: String, payer: String, attempts: Int, threshold: Double, windowDays: Int, dosageMg: Double, status: ManualAcuityPlanDraftStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.attempts = attempts
            self.threshold = threshold
            self.windowDays = windowDays
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualAcuityPlanDraftStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ManualAcuityPlanDraftStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualAcuityPlanDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual acuity plan draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual acuity plan draft") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(windowDays) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> ManualAcuityPlanDraft {
            return ManualAcuityPlanDraft(
                code: code,
                name: name,
                payer: payer,
                attempts: attempts,
                threshold: threshold,
                windowDays: windowDays,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual acuity plan draft in status requested.
    static func newManualAcuityPlanDraft(_ code: String, name: String) -> ManualAcuityPlanDraft {
        return ManualAcuityPlanDraft(
            code: code,
            name: name,
            payer: "",
            attempts: 0,
            threshold: 0.0,
            windowDays: 0,
            dosageMg: 0.0,
            status: ManualAcuityPlanDraftStatus.requested
        )
    }
}
