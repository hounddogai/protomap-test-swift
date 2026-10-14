import AcmePlatform
import Foundation

extension Staffing {
    /// Where a lenient acuity plan policy is in its life cycle.
    enum LenientAcuityPlanPolicyStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One lenient acuity plan policy, with what the planners need to act on it.
    final class LenientAcuityPlanPolicy {
        var code: String
        var label: String
        var capacity: Int
        var createdAt: Int
        var visible: Bool
        var acuity: Int
        var specialty: String
        var dosageMg: Double
        var summary: String
        var updatedAt: Int
        var notes: String
        var status: LenientAcuityPlanPolicyStatus

        init(code: String, label: String, capacity: Int, createdAt: Int, visible: Bool, acuity: Int, specialty: String, dosageMg: Double, summary: String, updatedAt: Int, notes: String, status: LenientAcuityPlanPolicyStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.createdAt = createdAt
            self.visible = visible
            self.acuity = acuity
            self.specialty = specialty
            self.dosageMg = dosageMg
            self.summary = summary
            self.updatedAt = updatedAt
            self.notes = notes
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

        func canMoveTo(_ next: LenientAcuityPlanPolicyStatus) -> Bool {
            switch status {
            case .new:
                return next == LenientAcuityPlanPolicyStatus.running || next == LenientAcuityPlanPolicyStatus.done
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == LenientAcuityPlanPolicyStatus.done || next == LenientAcuityPlanPolicyStatus.failed
            case .done:
                return next == LenientAcuityPlanPolicyStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientAcuityPlanPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient acuity plan policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("lenient acuity plan policy") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(updatedAt) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> LenientAcuityPlanPolicy {
            return LenientAcuityPlanPolicy(
                code: code,
                label: label,
                capacity: capacity,
                createdAt: createdAt,
                visible: visible,
                acuity: acuity,
                specialty: specialty,
                dosageMg: dosageMg,
                summary: summary,
                updatedAt: updatedAt,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient acuity plan policy in status new.
    static func newLenientAcuityPlanPolicy(_ code: String, label: String) -> LenientAcuityPlanPolicy {
        return LenientAcuityPlanPolicy(
            code: code,
            label: label,
            capacity: 0,
            createdAt: 0,
            visible: false,
            acuity: 0,
            specialty: "",
            dosageMg: 0.0,
            summary: "",
            updatedAt: 0,
            notes: "",
            status: LenientAcuityPlanPolicyStatus.new
        )
    }
}
