import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol checkpoint is in its life cycle.
    enum CareProtocolCheckpointStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a care protocol checkpoint and its current status.
    final class CareProtocolCheckpoint {
        var code: String
        var title: String
        var country: String
        var region: String
        var discount: Double
        var payer: String
        var weight: Double
        var attempts: Int
        var endsAt: Int
        var locale: String
        var floorValue: Double
        var status: CareProtocolCheckpointStatus

        init(code: String, title: String, country: String, region: String, discount: Double, payer: String, weight: Double, attempts: Int, endsAt: Int, locale: String, floorValue: Double, status: CareProtocolCheckpointStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.region = region
            self.discount = discount
            self.payer = payer
            self.weight = weight
            self.attempts = attempts
            self.endsAt = endsAt
            self.locale = locale
            self.floorValue = floorValue
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

        func canMoveTo(_ next: CareProtocolCheckpointStatus) -> Bool {
            switch status {
            case .new:
                return next == CareProtocolCheckpointStatus.running
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == CareProtocolCheckpointStatus.done || next == CareProtocolCheckpointStatus.failed
            case .done:
                return next == CareProtocolCheckpointStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedVolume() -> Double {
            return ((floorValue + discount) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolCheckpoint {
            return CareProtocolCheckpoint(
                code: code,
                title: title,
                country: country,
                region: region,
                discount: discount,
                payer: payer,
                weight: weight,
                attempts: attempts,
                endsAt: endsAt,
                locale: locale,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a care protocol checkpoint in status new.
    static func newCareProtocolCheckpoint(_ code: String, title: String) -> CareProtocolCheckpoint {
        return CareProtocolCheckpoint(
            code: code,
            title: title,
            country: "",
            region: "",
            discount: 0.0,
            payer: "",
            weight: 0.0,
            attempts: 0,
            endsAt: 0,
            locale: "",
            floorValue: 0.0,
            status: CareProtocolCheckpointStatus.new
        )
    }
}
