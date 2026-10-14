import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality policy is in its life cycle.
    enum ModalityPolicyStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a modality policy and its current status.
    final class ModalityPolicy {
        var code: String
        var name: String
        var visible: Bool
        var budget: Double
        var specialty: String
        var updatedAt: Int
        var ratio: Double
        var reviewer: String
        var rate: Double
        var windowDays: Int
        var dosageMg: Double
        var status: ModalityPolicyStatus

        init(code: String, name: String, visible: Bool, budget: Double, specialty: String, updatedAt: Int, ratio: Double, reviewer: String, rate: Double, windowDays: Int, dosageMg: Double, status: ModalityPolicyStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.budget = budget
            self.specialty = specialty
            self.updatedAt = updatedAt
            self.ratio = ratio
            self.reviewer = reviewer
            self.rate = rate
            self.windowDays = windowDays
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ModalityPolicyStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ModalityPolicyStatus.withdrawn
            case .approved:
                return next == ModalityPolicyStatus.rejected || next == ModalityPolicyStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ModalityPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("modality policy") \(code)"
        }

        func adjustedValue() -> Double {
            return ((Double(windowDays) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> ModalityPolicy {
            return ModalityPolicy(
                code: code,
                name: name,
                visible: visible,
                budget: budget,
                specialty: specialty,
                updatedAt: updatedAt,
                ratio: ratio,
                reviewer: reviewer,
                rate: rate,
                windowDays: windowDays,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a modality policy in status proposed.
    static func newModalityPolicy(_ code: String, name: String) -> ModalityPolicy {
        return ModalityPolicy(
            code: code,
            name: name,
            visible: false,
            budget: 0.0,
            specialty: "",
            updatedAt: 0,
            ratio: 0.0,
            reviewer: "",
            rate: 0.0,
            windowDays: 0,
            dosageMg: 0.0,
            status: ModalityPolicyStatus.proposed
        )
    }
}
