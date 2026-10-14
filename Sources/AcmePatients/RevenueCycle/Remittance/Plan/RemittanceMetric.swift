import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance metric is in its life cycle.
    enum RemittanceMetricStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A remittance metric. Its code is unique within a tenant.
    final class RemittanceMetric {
        var code: String
        var title: String
        var graceDays: Int
        var contactEmail: String
        var patientRef: String
        var minimum: Double
        var payer: String
        var copay: Double
        var phone: String
        var capacity: Int
        var updatedAt: Int
        var status: RemittanceMetricStatus

        init(code: String, title: String, graceDays: Int, contactEmail: String, patientRef: String, minimum: Double, payer: String, copay: Double, phone: String, capacity: Int, updatedAt: Int, status: RemittanceMetricStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.contactEmail = contactEmail
            self.patientRef = patientRef
            self.minimum = minimum
            self.payer = payer
            self.copay = copay
            self.phone = phone
            self.capacity = capacity
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: RemittanceMetricStatus) -> Bool {
            switch status {
            case .idle:
                return next == RemittanceMetricStatus.warming || next == RemittanceMetricStatus.stopped
            case .warming:
                return next == RemittanceMetricStatus.ready || next == RemittanceMetricStatus.draining
            case .ready:
                return next == RemittanceMetricStatus.draining || next == RemittanceMetricStatus.stopped
            case .draining:
                return next == RemittanceMetricStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedLoad() -> Double {
            return (copay * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceMetric {
            return RemittanceMetric(
                code: code,
                title: title,
                graceDays: graceDays,
                contactEmail: contactEmail,
                patientRef: patientRef,
                minimum: minimum,
                payer: payer,
                copay: copay,
                phone: phone,
                capacity: capacity,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a remittance metric in status idle.
    static func newRemittanceMetric(_ code: String, title: String) -> RemittanceMetric {
        return RemittanceMetric(
            code: code,
            title: title,
            graceDays: 0,
            contactEmail: "",
            patientRef: "",
            minimum: 0.0,
            payer: "",
            copay: 0.0,
            phone: "",
            capacity: 0,
            updatedAt: 0,
            status: RemittanceMetricStatus.idle
        )
    }
}
