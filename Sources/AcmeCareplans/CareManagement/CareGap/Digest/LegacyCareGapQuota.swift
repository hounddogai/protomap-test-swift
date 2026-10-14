import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a legacy care gap quota is in its life cycle.
    enum LegacyCareGapQuotaStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a legacy care gap quota and its current status.
    final class LegacyCareGapQuota {
        var code: String
        var label: String
        var copay: Double
        var channel: String
        var limit: Int
        var windowDays: Int
        var bed: String
        var status: LegacyCareGapQuotaStatus

        init(code: String, label: String, copay: Double, channel: String, limit: Int, windowDays: Int, bed: String, status: LegacyCareGapQuotaStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.channel = channel
            self.limit = limit
            self.windowDays = windowDays
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyCareGapQuotaStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == LegacyCareGapQuotaStatus.active || next == LegacyCareGapQuotaStatus.closed
            case .active:
                return next == LegacyCareGapQuotaStatus.suspended || next == LegacyCareGapQuotaStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: LegacyCareGapQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy care gap quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("legacy care gap quota") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(limit) + copay) * 100).rounded() / 100
        }

        func copyValue() -> LegacyCareGapQuota {
            return LegacyCareGapQuota(
                code: code,
                label: label,
                copay: copay,
                channel: channel,
                limit: limit,
                windowDays: windowDays,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a legacy care gap quota in status draft.
    static func newLegacyCareGapQuota(_ code: String, label: String) -> LegacyCareGapQuota {
        return LegacyCareGapQuota(
            code: code,
            label: label,
            copay: 0.0,
            channel: "",
            limit: 0,
            windowDays: 0,
            bed: "",
            status: LegacyCareGapQuotaStatus.draft
        )
    }
}
