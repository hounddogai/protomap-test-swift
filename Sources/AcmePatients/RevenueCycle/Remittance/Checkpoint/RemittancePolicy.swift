import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance policy is in its life cycle.
    enum RemittancePolicyStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A remittance policy. Its code is unique within a tenant.
    final class RemittancePolicy {
        var code: String
        var title: String
        var allergy: String
        var durationMinutes: Int
        var batchSize: Int
        var archived: Bool
        var amount: Double
        var procedureCode: String
        var status: RemittancePolicyStatus

        init(code: String, title: String, allergy: String, durationMinutes: Int, batchSize: Int, archived: Bool, amount: Double, procedureCode: String, status: RemittancePolicyStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.durationMinutes = durationMinutes
            self.batchSize = batchSize
            self.archived = archived
            self.amount = amount
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: RemittancePolicyStatus) -> Bool {
            switch status {
            case .idle:
                return next == RemittancePolicyStatus.stopped
            case .warming:
                return next == RemittancePolicyStatus.draining || next == RemittancePolicyStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RemittancePolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedVolume() -> Double {
            return ((Double(batchSize) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RemittancePolicy {
            return RemittancePolicy(
                code: code,
                title: title,
                allergy: allergy,
                durationMinutes: durationMinutes,
                batchSize: batchSize,
                archived: archived,
                amount: amount,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a remittance policy in status idle.
    static func newRemittancePolicy(_ code: String, title: String) -> RemittancePolicy {
        return RemittancePolicy(
            code: code,
            title: title,
            allergy: "",
            durationMinutes: 0,
            batchSize: 0,
            archived: false,
            amount: 0.0,
            procedureCode: "",
            status: RemittancePolicyStatus.idle
        )
    }
}
