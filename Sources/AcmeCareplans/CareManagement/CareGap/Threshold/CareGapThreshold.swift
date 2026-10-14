import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap threshold is in its life cycle.
    enum CareGapThresholdStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A care gap threshold. Its code is unique within a tenant.
    final class CareGapThreshold {
        var code: String
        var name: String
        var quantity: Int
        var tags: [String]
        var source: String
        var status: CareGapThresholdStatus

        init(code: String, name: String, quantity: Int, tags: [String], source: String, status: CareGapThresholdStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.tags = tags
            self.source = source
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

        func canMoveTo(_ next: CareGapThresholdStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == CareGapThresholdStatus.revoked || next == CareGapThresholdStatus.expired
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

        func moveTo(_ next: CareGapThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("care gap threshold") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> CareGapThreshold {
            return CareGapThreshold(
                code: code,
                name: name,
                quantity: quantity,
                tags: tags,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a care gap threshold in status requested.
    static func newCareGapThreshold(_ code: String, name: String) -> CareGapThreshold {
        return CareGapThreshold(
            code: code,
            name: name,
            quantity: 0,
            tags: [],
            source: "",
            status: CareGapThresholdStatus.requested
        )
    }
}
