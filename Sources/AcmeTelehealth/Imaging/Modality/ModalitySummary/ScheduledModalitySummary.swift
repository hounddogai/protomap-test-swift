import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled modality summary is in its life cycle.
    enum ScheduledModalitySummaryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a scheduled modality summary and its current status.
    final class ScheduledModalitySummary {
        var code: String
        var name: String
        var checksum: String
        var weight: Double
        var ownerID: String
        var quantity: Int
        var ward: String
        var rate: Double
        var contactEmail: String
        var batchSize: Int
        var channel: String
        var status: ScheduledModalitySummaryStatus

        init(code: String, name: String, checksum: String, weight: Double, ownerID: String, quantity: Int, ward: String, rate: Double, contactEmail: String, batchSize: Int, channel: String, status: ScheduledModalitySummaryStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.weight = weight
            self.ownerID = ownerID
            self.quantity = quantity
            self.ward = ward
            self.rate = rate
            self.contactEmail = contactEmail
            self.batchSize = batchSize
            self.channel = channel
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

        func canMoveTo(_ next: ScheduledModalitySummaryStatus) -> Bool {
            switch status {
            case .requested:
                return next == ScheduledModalitySummaryStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
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

        func moveTo(_ next: ScheduledModalitySummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled modality summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled modality summary") \(code)"
        }

        func effectiveExposure() -> Double {
            return (weight * rate * 100).rounded() / 100
        }

        func copyValue() -> ScheduledModalitySummary {
            return ScheduledModalitySummary(
                code: code,
                name: name,
                checksum: checksum,
                weight: weight,
                ownerID: ownerID,
                quantity: quantity,
                ward: ward,
                rate: rate,
                contactEmail: contactEmail,
                batchSize: batchSize,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a scheduled modality summary in status requested.
    static func newScheduledModalitySummary(_ code: String, name: String) -> ScheduledModalitySummary {
        return ScheduledModalitySummary(
            code: code,
            name: name,
            checksum: "",
            weight: 0.0,
            ownerID: "",
            quantity: 0,
            ward: "",
            rate: 0.0,
            contactEmail: "",
            batchSize: 0,
            channel: "",
            status: ScheduledModalitySummaryStatus.requested
        )
    }
}
