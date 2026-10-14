import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial mapping is in its life cycle.
    enum DenialMappingStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a denial mapping and its current status.
    final class DenialMapping {
        var code: String
        var label: String
        var expiresAt: Int
        var procedureCode: String
        var maximum: Double
        var limit: Int
        var rate: Double
        var status: DenialMappingStatus

        init(code: String, label: String, expiresAt: Int, procedureCode: String, maximum: Double, limit: Int, rate: Double, status: DenialMappingStatus) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.procedureCode = procedureCode
            self.maximum = maximum
            self.limit = limit
            self.rate = rate
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

        func canMoveTo(_ next: DenialMappingStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
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
                return next == DenialMappingStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DenialMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("denial mapping") \(code)"
        }

        func weightedExposure() -> Double {
            return (maximum * rate * 100).rounded() / 100
        }

        func copyValue() -> DenialMapping {
            return DenialMapping(
                code: code,
                label: label,
                expiresAt: expiresAt,
                procedureCode: procedureCode,
                maximum: maximum,
                limit: limit,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a denial mapping in status new.
    static func newDenialMapping(_ code: String, label: String) -> DenialMapping {
        return DenialMapping(
            code: code,
            label: label,
            expiresAt: 0,
            procedureCode: "",
            maximum: 0.0,
            limit: 0,
            rate: 0.0,
            status: DenialMappingStatus.new
        )
    }
}
