import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy notice is in its life cycle.
    enum ProxyNoticeStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One proxy notice, with what the planners need to act on it.
    final class ProxyNotice {
        var code: String
        var label: String
        var createdAt: Int
        var endsAt: Int
        var windowDays: Int
        var facility: String
        var limit: Int
        var score: Double
        var region: String
        var visible: Bool
        var checksum: String
        var status: ProxyNoticeStatus

        init(code: String, label: String, createdAt: Int, endsAt: Int, windowDays: Int, facility: String, limit: Int, score: Double, region: String, visible: Bool, checksum: String, status: ProxyNoticeStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.endsAt = endsAt
            self.windowDays = windowDays
            self.facility = facility
            self.limit = limit
            self.score = score
            self.region = region
            self.visible = visible
            self.checksum = checksum
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

        func canMoveTo(_ next: ProxyNoticeStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == ProxyNoticeStatus.revoked || next == ProxyNoticeStatus.expired
            case .revoked:
                return next == ProxyNoticeStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("proxy notice") \(code)"
        }

        func adjustedValue() -> Double {
            return ((Double(createdAt) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> ProxyNotice {
            return ProxyNotice(
                code: code,
                label: label,
                createdAt: createdAt,
                endsAt: endsAt,
                windowDays: windowDays,
                facility: facility,
                limit: limit,
                score: score,
                region: region,
                visible: visible,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a proxy notice in status requested.
    static func newProxyNotice(_ code: String, label: String) -> ProxyNotice {
        return ProxyNotice(
            code: code,
            label: label,
            createdAt: 0,
            endsAt: 0,
            windowDays: 0,
            facility: "",
            limit: 0,
            score: 0.0,
            region: "",
            visible: false,
            checksum: "",
            status: ProxyNoticeStatus.requested
        )
    }
}
