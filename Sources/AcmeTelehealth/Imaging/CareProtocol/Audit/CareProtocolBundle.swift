import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol bundle is in its life cycle.
    enum CareProtocolBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A care protocol bundle. Its code is unique within a tenant.
    final class CareProtocolBundle {
        var code: String
        var name: String
        var floorValue: Double
        var channel: String
        var specialty: String
        var batchSize: Int
        var bed: String
        var updatedAt: Int
        var score: Double
        var graceDays: Int
        var status: CareProtocolBundleStatus

        init(code: String, name: String, floorValue: Double, channel: String, specialty: String, batchSize: Int, bed: String, updatedAt: Int, score: Double, graceDays: Int, status: CareProtocolBundleStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.channel = channel
            self.specialty = specialty
            self.batchSize = batchSize
            self.bed = bed
            self.updatedAt = updatedAt
            self.score = score
            self.graceDays = graceDays
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

        func canMoveTo(_ next: CareProtocolBundleStatus) -> Bool {
            switch status {
            case .idle:
                return next == CareProtocolBundleStatus.draining
            case .warming:
                return next == CareProtocolBundleStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == CareProtocolBundleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("care protocol bundle") \(code)"
        }

        func weightedLoad() -> Double {
            return (score * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolBundle {
            return CareProtocolBundle(
                code: code,
                name: name,
                floorValue: floorValue,
                channel: channel,
                specialty: specialty,
                batchSize: batchSize,
                bed: bed,
                updatedAt: updatedAt,
                score: score,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a care protocol bundle in status idle.
    static func newCareProtocolBundle(_ code: String, name: String) -> CareProtocolBundle {
        return CareProtocolBundle(
            code: code,
            name: name,
            floorValue: 0.0,
            channel: "",
            specialty: "",
            batchSize: 0,
            bed: "",
            updatedAt: 0,
            score: 0.0,
            graceDays: 0,
            status: CareProtocolBundleStatus.idle
        )
    }
}
