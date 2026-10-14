import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim exception is in its life cycle.
    enum ClaimExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A claim exception as the claim team keeps it.
    final class ClaimException {
        var code: String
        var title: String
        var externalRef: String
        var ward: String
        var name: String
        var discount: Double
        var limit: Int
        var acuity: Int
        var diagnosisCode: String
        var status: ClaimExceptionStatus

        init(code: String, title: String, externalRef: String, ward: String, name: String, discount: Double, limit: Int, acuity: Int, diagnosisCode: String, status: ClaimExceptionStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.ward = ward
            self.name = name
            self.discount = discount
            self.limit = limit
            self.acuity = acuity
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: ClaimExceptionStatus) -> Bool {
            switch status {
            case .idle:
                return next == ClaimExceptionStatus.warming || next == ClaimExceptionStatus.stopped
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
                case .stopped:
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

        func moveTo(_ next: ClaimExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedExposure() -> Double {
            return ((discount - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> ClaimException {
            return ClaimException(
                code: code,
                title: title,
                externalRef: externalRef,
                ward: ward,
                name: name,
                discount: discount,
                limit: limit,
                acuity: acuity,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a claim exception in status idle.
    static func newClaimException(_ code: String, title: String) -> ClaimException {
        return ClaimException(
            code: code,
            title: title,
            externalRef: "",
            ward: "",
            name: "",
            discount: 0.0,
            limit: 0,
            acuity: 0,
            diagnosisCode: "",
            status: ClaimExceptionStatus.idle
        )
    }
}
