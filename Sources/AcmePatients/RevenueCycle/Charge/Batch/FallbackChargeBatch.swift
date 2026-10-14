import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback charge batch is in its life cycle.
    enum FallbackChargeBatchStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback charge batch. Its code is unique within a tenant.
    final class FallbackChargeBatch {
        var code: String
        var name: String
        var discount: Double
        var title: String
        var facility: String
        var clinicianID: String
        var status: FallbackChargeBatchStatus

        init(code: String, name: String, discount: Double, title: String, facility: String, clinicianID: String, status: FallbackChargeBatchStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.title = title
            self.facility = facility
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: FallbackChargeBatchStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == FallbackChargeBatchStatus.ready
            case .ready:
                return next == FallbackChargeBatchStatus.draining || next == FallbackChargeBatchStatus.stopped
            case .draining:
                return next == FallbackChargeBatchStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackChargeBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback charge batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> FallbackChargeBatch {
            return FallbackChargeBatch(
                code: code,
                name: name,
                discount: discount,
                title: title,
                facility: facility,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a fallback charge batch in status idle.
    static func newFallbackChargeBatch(_ code: String, name: String) -> FallbackChargeBatch {
        return FallbackChargeBatch(
            code: code,
            name: name,
            discount: 0.0,
            title: "",
            facility: "",
            clinicianID: "",
            status: FallbackChargeBatchStatus.idle
        )
    }
}
