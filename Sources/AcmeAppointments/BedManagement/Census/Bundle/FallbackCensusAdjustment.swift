import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a fallback census adjustment is in its life cycle.
    enum FallbackCensusAdjustmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback census adjustment. Its code is unique within a tenant.
    final class FallbackCensusAdjustment {
        var code: String
        var name: String
        var checksum: String
        var acuity: Int
        var copay: Double
        var label: String
        var amount: Double
        var visitMinutes: Int
        var priority: Int
        var patientRef: String
        var quantity: Int
        var status: FallbackCensusAdjustmentStatus

        init(code: String, name: String, checksum: String, acuity: Int, copay: Double, label: String, amount: Double, visitMinutes: Int, priority: Int, patientRef: String, quantity: Int, status: FallbackCensusAdjustmentStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.acuity = acuity
            self.copay = copay
            self.label = label
            self.amount = amount
            self.visitMinutes = visitMinutes
            self.priority = priority
            self.patientRef = patientRef
            self.quantity = quantity
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

        func canMoveTo(_ next: FallbackCensusAdjustmentStatus) -> Bool {
            switch status {
            case .idle:
                return next == FallbackCensusAdjustmentStatus.warming
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == FallbackCensusAdjustmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackCensusAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback census adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("fallback census adjustment") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(quantity) - copay) * 100).rounded() / 100
        }

        func copyValue() -> FallbackCensusAdjustment {
            return FallbackCensusAdjustment(
                code: code,
                name: name,
                checksum: checksum,
                acuity: acuity,
                copay: copay,
                label: label,
                amount: amount,
                visitMinutes: visitMinutes,
                priority: priority,
                patientRef: patientRef,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback census adjustment in status idle.
    static func newFallbackCensusAdjustment(_ code: String, name: String) -> FallbackCensusAdjustment {
        return FallbackCensusAdjustment(
            code: code,
            name: name,
            checksum: "",
            acuity: 0,
            copay: 0.0,
            label: "",
            amount: 0.0,
            visitMinutes: 0,
            priority: 0,
            patientRef: "",
            quantity: 0,
            status: FallbackCensusAdjustmentStatus.idle
        )
    }
}
