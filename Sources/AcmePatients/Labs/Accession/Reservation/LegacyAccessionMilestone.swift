import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy accession milestone is in its life cycle.
    enum LegacyAccessionMilestoneStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A legacy accession milestone as the accession team keeps it.
    final class LegacyAccessionMilestone {
        var code: String
        var label: String
        var graceDays: Int
        var version: Int
        var reviewer: String
        var segment: String
        var durationMinutes: Int
        var ward: String
        var country: String
        var status: LegacyAccessionMilestoneStatus

        init(code: String, label: String, graceDays: Int, version: Int, reviewer: String, segment: String, durationMinutes: Int, ward: String, country: String, status: LegacyAccessionMilestoneStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.version = version
            self.reviewer = reviewer
            self.segment = segment
            self.durationMinutes = durationMinutes
            self.ward = ward
            self.country = country
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

        func canMoveTo(_ next: LegacyAccessionMilestoneStatus) -> Bool {
            switch status {
            case .idle:
                return next == LegacyAccessionMilestoneStatus.warming
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == LegacyAccessionMilestoneStatus.draining || next == LegacyAccessionMilestoneStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: LegacyAccessionMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy accession milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedVolume() -> Double {
            return ((Double(graceDays) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyAccessionMilestone {
            return LegacyAccessionMilestone(
                code: code,
                label: label,
                graceDays: graceDays,
                version: version,
                reviewer: reviewer,
                segment: segment,
                durationMinutes: durationMinutes,
                ward: ward,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a legacy accession milestone in status idle.
    static func newLegacyAccessionMilestone(_ code: String, label: String) -> LegacyAccessionMilestone {
        return LegacyAccessionMilestone(
            code: code,
            label: label,
            graceDays: 0,
            version: 0,
            reviewer: "",
            segment: "",
            durationMinutes: 0,
            ward: "",
            country: "",
            status: LegacyAccessionMilestoneStatus.idle
        )
    }
}
