import AcmePlatform
import Foundation

extension Consent {
    /// Where a fallback revocation tier is in its life cycle.
    enum FallbackRevocationTierStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a fallback revocation tier and its current status.
    final class FallbackRevocationTier {
        var code: String
        var label: String
        var visible: Bool
        var region: String
        var locale: String
        var reviewer: String
        var batchSize: Int
        var bed: String
        var createdAt: Int
        var updatedAt: Int
        var status: FallbackRevocationTierStatus

        init(code: String, label: String, visible: Bool, region: String, locale: String, reviewer: String, batchSize: Int, bed: String, createdAt: Int, updatedAt: Int, status: FallbackRevocationTierStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.region = region
            self.locale = locale
            self.reviewer = reviewer
            self.batchSize = batchSize
            self.bed = bed
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackRevocationTierStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == FallbackRevocationTierStatus.inProgress
            case .inProgress:
                return next == FallbackRevocationTierStatus.completed || next == FallbackRevocationTierStatus.cancelled
            case .completed:
                return next == FallbackRevocationTierStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackRevocationTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback revocation tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("fallback revocation tier") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(batchSize) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackRevocationTier {
            return FallbackRevocationTier(
                code: code,
                label: label,
                visible: visible,
                region: region,
                locale: locale,
                reviewer: reviewer,
                batchSize: batchSize,
                bed: bed,
                createdAt: createdAt,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a fallback revocation tier in status planned.
    static func newFallbackRevocationTier(_ code: String, label: String) -> FallbackRevocationTier {
        return FallbackRevocationTier(
            code: code,
            label: label,
            visible: false,
            region: "",
            locale: "",
            reviewer: "",
            batchSize: 0,
            bed: "",
            createdAt: 0,
            updatedAt: 0,
            status: FallbackRevocationTierStatus.planned
        )
    }
}
