import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual recall notice is in its life cycle.
    enum ManualRecallNoticeStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A manual recall notice. Its code is unique within a tenant.
    final class ManualRecallNotice {
        var code: String
        var label: String
        var locale: String
        var bed: String
        var region: String
        var version: Int
        var attributes: [String: String]
        var amount: Double
        var status: ManualRecallNoticeStatus

        init(code: String, label: String, locale: String, bed: String, region: String, version: Int, attributes: [String: String], amount: Double, status: ManualRecallNoticeStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.bed = bed
            self.region = region
            self.version = version
            self.attributes = attributes
            self.amount = amount
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

        func canMoveTo(_ next: ManualRecallNoticeStatus) -> Bool {
            switch status {
            case .requested:
                return next == ManualRecallNoticeStatus.granted || next == ManualRecallNoticeStatus.revoked
            case .granted:
                return next == ManualRecallNoticeStatus.revoked
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

        func moveTo(_ next: ManualRecallNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual recall notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("manual recall notice") \(code)"
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

        func projectedExposure() -> Double {
            return ((amount - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> ManualRecallNotice {
            return ManualRecallNotice(
                code: code,
                label: label,
                locale: locale,
                bed: bed,
                region: region,
                version: version,
                attributes: attributes,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a manual recall notice in status requested.
    static func newManualRecallNotice(_ code: String, label: String) -> ManualRecallNotice {
        return ManualRecallNotice(
            code: code,
            label: label,
            locale: "",
            bed: "",
            region: "",
            version: 0,
            attributes: [:],
            amount: 0.0,
            status: ManualRecallNoticeStatus.requested
        )
    }
}
