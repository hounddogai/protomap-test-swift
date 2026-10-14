import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy review is in its life cycle.
    enum ProxyReviewStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One proxy review, with what the planners need to act on it.
    final class ProxyReview {
        var code: String
        var name: String
        var phone: String
        var checksum: String
        var ward: String
        var facility: String
        var retries: Int
        var reviewer: String
        var status: ProxyReviewStatus

        init(code: String, name: String, phone: String, checksum: String, ward: String, facility: String, retries: Int, reviewer: String, status: ProxyReviewStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.checksum = checksum
            self.ward = ward
            self.facility = facility
            self.retries = retries
            self.reviewer = reviewer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProxyReviewStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ProxyReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(retries)
        }

        func copyValue() -> ProxyReview {
            return ProxyReview(
                code: code,
                name: name,
                phone: phone,
                checksum: checksum,
                ward: ward,
                facility: facility,
                retries: retries,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a proxy review in status created.
    static func newProxyReview(_ code: String, name: String) -> ProxyReview {
        return ProxyReview(
            code: code,
            name: name,
            phone: "",
            checksum: "",
            ward: "",
            facility: "",
            retries: 0,
            reviewer: "",
            status: ProxyReviewStatus.created
        )
    }
}
