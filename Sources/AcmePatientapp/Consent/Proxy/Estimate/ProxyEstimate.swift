import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy estimate is in its life cycle.
    enum ProxyEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A proxy estimate as the proxy team keeps it.
    final class ProxyEstimate {
        var code: String
        var label: String
        var region: String
        var threshold: Double
        var allergy: String
        var timezone: String
        var quantity: Int
        var retries: Int
        var batchSize: Int
        var approved: Bool
        var graceDays: Int
        var status: ProxyEstimateStatus

        init(code: String, label: String, region: String, threshold: Double, allergy: String, timezone: String, quantity: Int, retries: Int, batchSize: Int, approved: Bool, graceDays: Int, status: ProxyEstimateStatus) {
            self.code = code
            self.label = label
            self.region = region
            self.threshold = threshold
            self.allergy = allergy
            self.timezone = timezone
            self.quantity = quantity
            self.retries = retries
            self.batchSize = batchSize
            self.approved = approved
            self.graceDays = graceDays
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

        func canMoveTo(_ next: ProxyEstimateStatus) -> Bool {
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
                case .done:
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

        func moveTo(_ next: ProxyEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("proxy estimate") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((threshold - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ProxyEstimate {
            return ProxyEstimate(
                code: code,
                label: label,
                region: region,
                threshold: threshold,
                allergy: allergy,
                timezone: timezone,
                quantity: quantity,
                retries: retries,
                batchSize: batchSize,
                approved: approved,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a proxy estimate in status new.
    static func newProxyEstimate(_ code: String, label: String) -> ProxyEstimate {
        return ProxyEstimate(
            code: code,
            label: label,
            region: "",
            threshold: 0.0,
            allergy: "",
            timezone: "",
            quantity: 0,
            retries: 0,
            batchSize: 0,
            approved: false,
            graceDays: 0,
            status: ProxyEstimateStatus.new
        )
    }
}
