import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered claim threshold is in its life cycle.
    enum TieredClaimThresholdStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a tiered claim threshold and its current status.
    final class TieredClaimThreshold {
        var code: String
        var label: String
        var summary: String
        var procedureCode: String
        var threshold: Double
        var phone: String
        var visitMinutes: Int
        var limit: Int
        var durationMinutes: Int
        var status: TieredClaimThresholdStatus

        init(code: String, label: String, summary: String, procedureCode: String, threshold: Double, phone: String, visitMinutes: Int, limit: Int, durationMinutes: Int, status: TieredClaimThresholdStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.procedureCode = procedureCode
            self.threshold = threshold
            self.phone = phone
            self.visitMinutes = visitMinutes
            self.limit = limit
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: TieredClaimThresholdStatus) -> Bool {
            switch status {
            case .idle:
                return next == TieredClaimThresholdStatus.warming
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == TieredClaimThresholdStatus.draining
            case .draining:
                return next == TieredClaimThresholdStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredClaimThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered claim threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("tiered claim threshold") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((Double(limit) + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> TieredClaimThreshold {
            return TieredClaimThreshold(
                code: code,
                label: label,
                summary: summary,
                procedureCode: procedureCode,
                threshold: threshold,
                phone: phone,
                visitMinutes: visitMinutes,
                limit: limit,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered claim threshold in status idle.
    static func newTieredClaimThreshold(_ code: String, label: String) -> TieredClaimThreshold {
        return TieredClaimThreshold(
            code: code,
            label: label,
            summary: "",
            procedureCode: "",
            threshold: 0.0,
            phone: "",
            visitMinutes: 0,
            limit: 0,
            durationMinutes: 0,
            status: TieredClaimThresholdStatus.idle
        )
    }
}
