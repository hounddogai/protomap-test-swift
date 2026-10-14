import AcmePlatform
import Foundation

extension Staffing {
    /// Where a rolling shift manifest is in its life cycle.
    enum RollingShiftManifestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One rolling shift manifest, with what the planners need to act on it.
    final class RollingShiftManifest {
        var code: String
        var name: String
        var revision: Int
        var amount: Double
        var threshold: Double
        var ownerID: String
        var region: String
        var version: Int
        var floorValue: Double
        var segment: String
        var endsAt: Int
        var status: RollingShiftManifestStatus

        init(code: String, name: String, revision: Int, amount: Double, threshold: Double, ownerID: String, region: String, version: Int, floorValue: Double, segment: String, endsAt: Int, status: RollingShiftManifestStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.amount = amount
            self.threshold = threshold
            self.ownerID = ownerID
            self.region = region
            self.version = version
            self.floorValue = floorValue
            self.segment = segment
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingShiftManifestStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == RollingShiftManifestStatus.reopened
            case .resolved:
                return next == RollingShiftManifestStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: RollingShiftManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling shift manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("rolling shift manifest") \(code)"
        }

        func projectedValue() -> Double {
            return (floorValue * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> RollingShiftManifest {
            return RollingShiftManifest(
                code: code,
                name: name,
                revision: revision,
                amount: amount,
                threshold: threshold,
                ownerID: ownerID,
                region: region,
                version: version,
                floorValue: floorValue,
                segment: segment,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a rolling shift manifest in status open.
    static func newRollingShiftManifest(_ code: String, name: String) -> RollingShiftManifest {
        return RollingShiftManifest(
            code: code,
            name: name,
            revision: 0,
            amount: 0.0,
            threshold: 0.0,
            ownerID: "",
            region: "",
            version: 0,
            floorValue: 0.0,
            segment: "",
            endsAt: 0,
            status: RollingShiftManifestStatus.`open`
        )
    }
}
