import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality quota is in its life cycle.
    enum ModalityQuotaStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a modality quota and its current status.
    final class ModalityQuota {
        var code: String
        var title: String
        var payer: String
        var ward: String
        var version: Int
        var checksum: String
        var externalRef: String
        var country: String
        var segment: String
        var region: String
        var priority: Int
        var status: ModalityQuotaStatus

        init(code: String, title: String, payer: String, ward: String, version: Int, checksum: String, externalRef: String, country: String, segment: String, region: String, priority: Int, status: ModalityQuotaStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.ward = ward
            self.version = version
            self.checksum = checksum
            self.externalRef = externalRef
            self.country = country
            self.segment = segment
            self.region = region
            self.priority = priority
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

        func canMoveTo(_ next: ModalityQuotaStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ModalityQuotaStatus.draining || next == ModalityQuotaStatus.stopped
            case .ready:
                return next == ModalityQuotaStatus.draining || next == ModalityQuotaStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ModalityQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedVolume() -> Double {
            return ((Double(priority) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> ModalityQuota {
            return ModalityQuota(
                code: code,
                title: title,
                payer: payer,
                ward: ward,
                version: version,
                checksum: checksum,
                externalRef: externalRef,
                country: country,
                segment: segment,
                region: region,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a modality quota in status idle.
    static func newModalityQuota(_ code: String, title: String) -> ModalityQuota {
        return ModalityQuota(
            code: code,
            title: title,
            payer: "",
            ward: "",
            version: 0,
            checksum: "",
            externalRef: "",
            country: "",
            segment: "",
            region: "",
            priority: 0,
            status: ModalityQuotaStatus.idle
        )
    }
}
