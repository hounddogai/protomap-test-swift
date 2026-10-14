import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score tier is in its life cycle.
    enum RiskScoreTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a risk score tier and its current status.
    final class RiskScoreTier {
        var code: String
        var label: String
        var visitMinutes: Int
        var checksum: String
        var refills: Int
        var status: RiskScoreTierStatus

        init(code: String, label: String, visitMinutes: Int, checksum: String, refills: Int, status: RiskScoreTierStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.checksum = checksum
            self.refills = refills
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

        func canMoveTo(_ next: RiskScoreTierStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RiskScoreTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("risk score tier") \(code)"
        }

        func effectiveExposure() -> Double {
            return (Double(refills) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreTier {
            return RiskScoreTier(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                checksum: checksum,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a risk score tier in status new.
    static func newRiskScoreTier(_ code: String, label: String) -> RiskScoreTier {
        return RiskScoreTier(
            code: code,
            label: label,
            visitMinutes: 0,
            checksum: "",
            refills: 0,
            status: RiskScoreTierStatus.new
        )
    }
}
