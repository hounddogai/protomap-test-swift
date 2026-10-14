import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up cycle is in its life cycle.
    enum FollowUpCycleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A follow up cycle. Its code is unique within a tenant.
    final class FollowUpCycle {
        var code: String
        var label: String
        var source: String
        var expiresAt: Int
        var ward: String
        var margin: Double
        var checksum: String
        var acuity: Int
        var payer: String
        var batchSize: Int
        var status: FollowUpCycleStatus

        init(code: String, label: String, source: String, expiresAt: Int, ward: String, margin: Double, checksum: String, acuity: Int, payer: String, batchSize: Int, status: FollowUpCycleStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.expiresAt = expiresAt
            self.ward = ward
            self.margin = margin
            self.checksum = checksum
            self.acuity = acuity
            self.payer = payer
            self.batchSize = batchSize
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

        func canMoveTo(_ next: FollowUpCycleStatus) -> Bool {
            switch status {
            case .new:
                return next == FollowUpCycleStatus.failed
            case .queued:
                return next == FollowUpCycleStatus.running || next == FollowUpCycleStatus.done
            case .running:
                return next == FollowUpCycleStatus.failed
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

        func moveTo(_ next: FollowUpCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("follow up cycle") \(code)"
        }

        func netValue() -> Double {
            return ((Double(expiresAt) + margin) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpCycle {
            return FollowUpCycle(
                code: code,
                label: label,
                source: source,
                expiresAt: expiresAt,
                ward: ward,
                margin: margin,
                checksum: checksum,
                acuity: acuity,
                payer: payer,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a follow up cycle in status new.
    static func newFollowUpCycle(_ code: String, label: String) -> FollowUpCycle {
        return FollowUpCycle(
            code: code,
            label: label,
            source: "",
            expiresAt: 0,
            ward: "",
            margin: 0.0,
            checksum: "",
            acuity: 0,
            payer: "",
            batchSize: 0,
            status: FollowUpCycleStatus.new
        )
    }
}
