import AcmePlatform
import Foundation

extension Consent {
    /// Where a fallback disclosure adjustment is in its life cycle.
    enum FallbackDisclosureAdjustmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A fallback disclosure adjustment. Its code is unique within a tenant.
    final class FallbackDisclosureAdjustment {
        var code: String
        var name: String
        var priority: Int
        var batchSize: Int
        var phone: String
        var dosageMg: Double
        var region: String
        var patientRef: String
        var cost: Double
        var revision: Int
        var status: FallbackDisclosureAdjustmentStatus

        init(code: String, name: String, priority: Int, batchSize: Int, phone: String, dosageMg: Double, region: String, patientRef: String, cost: Double, revision: Int, status: FallbackDisclosureAdjustmentStatus) {
            self.code = code
            self.name = name
            self.priority = priority
            self.batchSize = batchSize
            self.phone = phone
            self.dosageMg = dosageMg
            self.region = region
            self.patientRef = patientRef
            self.cost = cost
            self.revision = revision
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

        func canMoveTo(_ next: FallbackDisclosureAdjustmentStatus) -> Bool {
            switch status {
            case .created:
                return next == FallbackDisclosureAdjustmentStatus.validated || next == FallbackDisclosureAdjustmentStatus.retired
            case .validated:
                return next == FallbackDisclosureAdjustmentStatus.retired
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

        func moveTo(_ next: FallbackDisclosureAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback disclosure adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("fallback disclosure adjustment") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(priority) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> FallbackDisclosureAdjustment {
            return FallbackDisclosureAdjustment(
                code: code,
                name: name,
                priority: priority,
                batchSize: batchSize,
                phone: phone,
                dosageMg: dosageMg,
                region: region,
                patientRef: patientRef,
                cost: cost,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a fallback disclosure adjustment in status created.
    static func newFallbackDisclosureAdjustment(_ code: String, name: String) -> FallbackDisclosureAdjustment {
        return FallbackDisclosureAdjustment(
            code: code,
            name: name,
            priority: 0,
            batchSize: 0,
            phone: "",
            dosageMg: 0.0,
            region: "",
            patientRef: "",
            cost: 0.0,
            revision: 0,
            status: FallbackDisclosureAdjustmentStatus.created
        )
    }
}
