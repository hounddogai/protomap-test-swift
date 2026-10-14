import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential profile is in its life cycle.
    enum CredentialProfileStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a credential profile and its current status.
    final class CredentialProfile {
        var code: String
        var title: String
        var channel: String
        var minimum: Double
        var floorValue: Double
        var maximum: Double
        var version: Int
        var ownerID: String
        var weight: Double
        var unit: String
        var rate: Double
        var status: CredentialProfileStatus

        init(code: String, title: String, channel: String, minimum: Double, floorValue: Double, maximum: Double, version: Int, ownerID: String, weight: Double, unit: String, rate: Double, status: CredentialProfileStatus) {
            self.code = code
            self.title = title
            self.channel = channel
            self.minimum = minimum
            self.floorValue = floorValue
            self.maximum = maximum
            self.version = version
            self.ownerID = ownerID
            self.weight = weight
            self.unit = unit
            self.rate = rate
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

        func canMoveTo(_ next: CredentialProfileStatus) -> Bool {
            switch status {
            case .new:
                return next == CredentialProfileStatus.running || next == CredentialProfileStatus.done
            case .queued:
                return next == CredentialProfileStatus.done
            case .running:
                return next == CredentialProfileStatus.done || next == CredentialProfileStatus.failed
            case .done:
                return next == CredentialProfileStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netValue() -> Double {
            return ((floorValue + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> CredentialProfile {
            return CredentialProfile(
                code: code,
                title: title,
                channel: channel,
                minimum: minimum,
                floorValue: floorValue,
                maximum: maximum,
                version: version,
                ownerID: ownerID,
                weight: weight,
                unit: unit,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a credential profile in status new.
    static func newCredentialProfile(_ code: String, title: String) -> CredentialProfile {
        return CredentialProfile(
            code: code,
            title: title,
            channel: "",
            minimum: 0.0,
            floorValue: 0.0,
            maximum: 0.0,
            version: 0,
            ownerID: "",
            weight: 0.0,
            unit: "",
            rate: 0.0,
            status: CredentialProfileStatus.new
        )
    }
}
