import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a manual care protocol notice is in its life cycle.
    enum ManualCareProtocolNoticeStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A manual care protocol notice as the care protocol team keeps it.
    final class ManualCareProtocolNotice {
        var code: String
        var label: String
        var version: Int
        var floorValue: Double
        var priority: Int
        var category: String
        var status: ManualCareProtocolNoticeStatus

        init(code: String, label: String, version: Int, floorValue: Double, priority: Int, category: String, status: ManualCareProtocolNoticeStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.floorValue = floorValue
            self.priority = priority
            self.category = category
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

        func canMoveTo(_ next: ManualCareProtocolNoticeStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == ManualCareProtocolNoticeStatus.expired
            case .revoked:
                return next == ManualCareProtocolNoticeStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualCareProtocolNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual care protocol notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedValue() -> Double {
            return (Double(priority) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> ManualCareProtocolNotice {
            return ManualCareProtocolNotice(
                code: code,
                label: label,
                version: version,
                floorValue: floorValue,
                priority: priority,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a manual care protocol notice in status requested.
    static func newManualCareProtocolNotice(_ code: String, label: String) -> ManualCareProtocolNotice {
        return ManualCareProtocolNotice(
            code: code,
            label: label,
            version: 0,
            floorValue: 0.0,
            priority: 0,
            category: "",
            status: ManualCareProtocolNoticeStatus.requested
        )
    }
}
