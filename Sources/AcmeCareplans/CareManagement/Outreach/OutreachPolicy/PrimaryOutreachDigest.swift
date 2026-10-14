import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a primary outreach digest is in its life cycle.
    enum PrimaryOutreachDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a primary outreach digest and its current status.
    final class PrimaryOutreachDigest {
        var code: String
        var title: String
        var visible: Bool
        var ward: String
        var currency: String
        var quantity: Int
        var status: PrimaryOutreachDigestStatus

        init(code: String, title: String, visible: Bool, ward: String, currency: String, quantity: Int, status: PrimaryOutreachDigestStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.ward = ward
            self.currency = currency
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryOutreachDigestStatus) -> Bool {
            switch status {
            case .new:
                return next == PrimaryOutreachDigestStatus.running
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == PrimaryOutreachDigestStatus.done || next == PrimaryOutreachDigestStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: PrimaryOutreachDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary outreach digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary outreach digest") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> PrimaryOutreachDigest {
            return PrimaryOutreachDigest(
                code: code,
                title: title,
                visible: visible,
                ward: ward,
                currency: currency,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a primary outreach digest in status new.
    static func newPrimaryOutreachDigest(_ code: String, title: String) -> PrimaryOutreachDigest {
        return PrimaryOutreachDigest(
            code: code,
            title: title,
            visible: false,
            ward: "",
            currency: "",
            quantity: 0,
            status: PrimaryOutreachDigestStatus.new
        )
    }
}
