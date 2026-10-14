import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual transfer estimate is in its life cycle.
    enum ManualTransferEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A manual transfer estimate. Its code is unique within a tenant.
    final class ManualTransferEstimate {
        var code: String
        var name: String
        var description: String
        var channel: String
        var createdAt: Int
        var pinned: Bool
        var locale: String
        var phone: String
        var acuity: Int
        var status: ManualTransferEstimateStatus

        init(code: String, name: String, description: String, channel: String, createdAt: Int, pinned: Bool, locale: String, phone: String, acuity: Int, status: ManualTransferEstimateStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.channel = channel
            self.createdAt = createdAt
            self.pinned = pinned
            self.locale = locale
            self.phone = phone
            self.acuity = acuity
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

        func canMoveTo(_ next: ManualTransferEstimateStatus) -> Bool {
            switch status {
            case .requested:
                return next == ManualTransferEstimateStatus.revoked
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ManualTransferEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual transfer estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedValue() -> Double {
            return ((Double(createdAt) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> ManualTransferEstimate {
            return ManualTransferEstimate(
                code: code,
                name: name,
                description: description,
                channel: channel,
                createdAt: createdAt,
                pinned: pinned,
                locale: locale,
                phone: phone,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a manual transfer estimate in status requested.
    static func newManualTransferEstimate(_ code: String, name: String) -> ManualTransferEstimate {
        return ManualTransferEstimate(
            code: code,
            name: name,
            description: "",
            channel: "",
            createdAt: 0,
            pinned: false,
            locale: "",
            phone: "",
            acuity: 0,
            status: ManualTransferEstimateStatus.requested
        )
    }
}
