import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped courier exception is in its life cycle.
    enum CappedCourierExceptionStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a capped courier exception and its current status.
    final class CappedCourierException {
        var code: String
        var name: String
        var capacity: Int
        var copay: Double
        var endsAt: Int
        var budget: Double
        var threshold: Double
        var bed: String
        var cost: Double
        var refills: Int
        var status: CappedCourierExceptionStatus

        init(code: String, name: String, capacity: Int, copay: Double, endsAt: Int, budget: Double, threshold: Double, bed: String, cost: Double, refills: Int, status: CappedCourierExceptionStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.copay = copay
            self.endsAt = endsAt
            self.budget = budget
            self.threshold = threshold
            self.bed = bed
            self.cost = cost
            self.refills = refills
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

        func canMoveTo(_ next: CappedCourierExceptionStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == CappedCourierExceptionStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: CappedCourierExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped courier exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("capped courier exception") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((threshold + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> CappedCourierException {
            return CappedCourierException(
                code: code,
                name: name,
                capacity: capacity,
                copay: copay,
                endsAt: endsAt,
                budget: budget,
                threshold: threshold,
                bed: bed,
                cost: cost,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped courier exception in status requested.
    static func newCappedCourierException(_ code: String, name: String) -> CappedCourierException {
        return CappedCourierException(
            code: code,
            name: name,
            capacity: 0,
            copay: 0.0,
            endsAt: 0,
            budget: 0.0,
            threshold: 0.0,
            bed: "",
            cost: 0.0,
            refills: 0,
            status: CappedCourierExceptionStatus.requested
        )
    }
}
