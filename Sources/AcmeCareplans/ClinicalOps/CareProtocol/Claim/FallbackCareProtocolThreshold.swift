import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback care protocol threshold is in its life cycle.
    enum FallbackCareProtocolThresholdStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A fallback care protocol threshold. Its code is unique within a tenant.
    final class FallbackCareProtocolThreshold {
        var code: String
        var title: String
        var reviewer: String
        var sequence: Int
        var bed: String
        var maximum: Double
        var attributes: [String: String]
        var unit: String
        var limit: Int
        var status: FallbackCareProtocolThresholdStatus

        init(code: String, title: String, reviewer: String, sequence: Int, bed: String, maximum: Double, attributes: [String: String], unit: String, limit: Int, status: FallbackCareProtocolThresholdStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.sequence = sequence
            self.bed = bed
            self.maximum = maximum
            self.attributes = attributes
            self.unit = unit
            self.limit = limit
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

        func canMoveTo(_ next: FallbackCareProtocolThresholdStatus) -> Bool {
            switch status {
            case .requested:
                return next == FallbackCareProtocolThresholdStatus.granted || next == FallbackCareProtocolThresholdStatus.expired
            case .granted:
                return next == FallbackCareProtocolThresholdStatus.revoked || next == FallbackCareProtocolThresholdStatus.expired
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

        func moveTo(_ next: FallbackCareProtocolThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback care protocol threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedTotal() -> Double {
            return ((Double(limit) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> FallbackCareProtocolThreshold {
            return FallbackCareProtocolThreshold(
                code: code,
                title: title,
                reviewer: reviewer,
                sequence: sequence,
                bed: bed,
                maximum: maximum,
                attributes: attributes,
                unit: unit,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a fallback care protocol threshold in status requested.
    static func newFallbackCareProtocolThreshold(_ code: String, title: String) -> FallbackCareProtocolThreshold {
        return FallbackCareProtocolThreshold(
            code: code,
            title: title,
            reviewer: "",
            sequence: 0,
            bed: "",
            maximum: 0.0,
            attributes: [:],
            unit: "",
            limit: 0,
            status: FallbackCareProtocolThresholdStatus.requested
        )
    }
}
