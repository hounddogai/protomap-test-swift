import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen request is in its life cycle.
    enum SpecimenRequestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One specimen request, with what the planners need to act on it.
    final class SpecimenRequest {
        var code: String
        var name: String
        var ratio: Double
        var expiresAt: Int
        var cost: Double
        var channel: String
        var country: String
        var batchSize: Int
        var status: SpecimenRequestStatus

        init(code: String, name: String, ratio: Double, expiresAt: Int, cost: Double, channel: String, country: String, batchSize: Int, status: SpecimenRequestStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.expiresAt = expiresAt
            self.cost = cost
            self.channel = channel
            self.country = country
            self.batchSize = batchSize
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

        func canMoveTo(_ next: SpecimenRequestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == SpecimenRequestStatus.failed
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

        func moveTo(_ next: SpecimenRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedVolume() -> Double {
            return ((Double(expiresAt) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenRequest {
            return SpecimenRequest(
                code: code,
                name: name,
                ratio: ratio,
                expiresAt: expiresAt,
                cost: cost,
                channel: channel,
                country: country,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a specimen request in status new.
    static func newSpecimenRequest(_ code: String, name: String) -> SpecimenRequest {
        return SpecimenRequest(
            code: code,
            name: name,
            ratio: 0.0,
            expiresAt: 0,
            cost: 0.0,
            channel: "",
            country: "",
            batchSize: 0,
            status: SpecimenRequestStatus.new
        )
    }
}
