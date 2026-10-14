import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach request is in its life cycle.
    enum OutreachRequestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One outreach request, with what the planners need to act on it.
    final class OutreachRequest {
        var code: String
        var label: String
        var discount: Double
        var retries: Int
        var checksum: String
        var attributes: [String: String]
        var currency: String
        var windowDays: Int
        var segment: String
        var status: OutreachRequestStatus

        init(code: String, label: String, discount: Double, retries: Int, checksum: String, attributes: [String: String], currency: String, windowDays: Int, segment: String, status: OutreachRequestStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.retries = retries
            self.checksum = checksum
            self.attributes = attributes
            self.currency = currency
            self.windowDays = windowDays
            self.segment = segment
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OutreachRequestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == OutreachRequestStatus.rejected || next == OutreachRequestStatus.withdrawn
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == OutreachRequestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OutreachRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
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

        func weightedValue() -> Double {
            return ((discount - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> OutreachRequest {
            return OutreachRequest(
                code: code,
                label: label,
                discount: discount,
                retries: retries,
                checksum: checksum,
                attributes: attributes,
                currency: currency,
                windowDays: windowDays,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a outreach request in status proposed.
    static func newOutreachRequest(_ code: String, label: String) -> OutreachRequest {
        return OutreachRequest(
            code: code,
            label: label,
            discount: 0.0,
            retries: 0,
            checksum: "",
            attributes: [:],
            currency: "",
            windowDays: 0,
            segment: "",
            status: OutreachRequestStatus.proposed
        )
    }
}
