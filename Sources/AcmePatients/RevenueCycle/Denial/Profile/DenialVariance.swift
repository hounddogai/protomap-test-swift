import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial variance is in its life cycle.
    enum DenialVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One denial variance, with what the planners need to act on it.
    final class DenialVariance {
        var code: String
        var title: String
        var acuity: Int
        var facility: String
        var dosageMg: Double
        var expiresAt: Int
        var status: DenialVarianceStatus

        init(code: String, title: String, acuity: Int, facility: String, dosageMg: Double, expiresAt: Int, status: DenialVarianceStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.facility = facility
            self.dosageMg = dosageMg
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: DenialVarianceStatus) -> Bool {
            switch status {
            case .new:
                return next == DenialVarianceStatus.queued || next == DenialVarianceStatus.done
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == DenialVarianceStatus.done || next == DenialVarianceStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: DenialVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("denial variance") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(expiresAt) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> DenialVariance {
            return DenialVariance(
                code: code,
                title: title,
                acuity: acuity,
                facility: facility,
                dosageMg: dosageMg,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a denial variance in status new.
    static func newDenialVariance(_ code: String, title: String) -> DenialVariance {
        return DenialVariance(
            code: code,
            title: title,
            acuity: 0,
            facility: "",
            dosageMg: 0.0,
            expiresAt: 0,
            status: DenialVarianceStatus.new
        )
    }
}
