import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive reference range milestone is in its life cycle.
    enum AdaptiveReferenceRangeMilestoneStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A adaptive reference range milestone as the reference range team keeps it.
    final class AdaptiveReferenceRangeMilestone {
        var code: String
        var title: String
        var weight: Double
        var externalRef: String
        var version: Int
        var startsAt: Int
        var acuity: Int
        var durationMinutes: Int
        var minimum: Double
        var checksum: String
        var region: String
        var status: AdaptiveReferenceRangeMilestoneStatus

        init(code: String, title: String, weight: Double, externalRef: String, version: Int, startsAt: Int, acuity: Int, durationMinutes: Int, minimum: Double, checksum: String, region: String, status: AdaptiveReferenceRangeMilestoneStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.externalRef = externalRef
            self.version = version
            self.startsAt = startsAt
            self.acuity = acuity
            self.durationMinutes = durationMinutes
            self.minimum = minimum
            self.checksum = checksum
            self.region = region
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

        func canMoveTo(_ next: AdaptiveReferenceRangeMilestoneStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == AdaptiveReferenceRangeMilestoneStatus.rejected || next == AdaptiveReferenceRangeMilestoneStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: AdaptiveReferenceRangeMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive reference range milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netTotal() -> Double {
            return ((Double(version) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveReferenceRangeMilestone {
            return AdaptiveReferenceRangeMilestone(
                code: code,
                title: title,
                weight: weight,
                externalRef: externalRef,
                version: version,
                startsAt: startsAt,
                acuity: acuity,
                durationMinutes: durationMinutes,
                minimum: minimum,
                checksum: checksum,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a adaptive reference range milestone in status proposed.
    static func newAdaptiveReferenceRangeMilestone(_ code: String, title: String) -> AdaptiveReferenceRangeMilestone {
        return AdaptiveReferenceRangeMilestone(
            code: code,
            title: title,
            weight: 0.0,
            externalRef: "",
            version: 0,
            startsAt: 0,
            acuity: 0,
            durationMinutes: 0,
            minimum: 0.0,
            checksum: "",
            region: "",
            status: AdaptiveReferenceRangeMilestoneStatus.proposed
        )
    }
}
