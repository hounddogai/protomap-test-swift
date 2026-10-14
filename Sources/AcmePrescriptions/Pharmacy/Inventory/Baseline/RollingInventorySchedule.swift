import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a rolling inventory schedule is in its life cycle.
    enum RollingInventoryScheduleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A rolling inventory schedule. Its code is unique within a tenant.
    final class RollingInventorySchedule {
        var code: String
        var label: String
        var clinicianID: String
        var refills: Int
        var retries: Int
        var region: String
        var tags: [String]
        var threshold: Double
        var externalRef: String
        var copay: Double
        var limit: Int
        var status: RollingInventoryScheduleStatus

        init(code: String, label: String, clinicianID: String, refills: Int, retries: Int, region: String, tags: [String], threshold: Double, externalRef: String, copay: Double, limit: Int, status: RollingInventoryScheduleStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.refills = refills
            self.retries = retries
            self.region = region
            self.tags = tags
            self.threshold = threshold
            self.externalRef = externalRef
            self.copay = copay
            self.limit = limit
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

        func canMoveTo(_ next: RollingInventoryScheduleStatus) -> Bool {
            switch status {
            case .idle:
                return next == RollingInventoryScheduleStatus.draining
            case .warming:
                return next == RollingInventoryScheduleStatus.ready || next == RollingInventoryScheduleStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RollingInventoryScheduleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingInventoryScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling inventory schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedTotal() -> Double {
            return (Double(limit) * threshold * 100).rounded() / 100
        }

        func copyValue() -> RollingInventorySchedule {
            return RollingInventorySchedule(
                code: code,
                label: label,
                clinicianID: clinicianID,
                refills: refills,
                retries: retries,
                region: region,
                tags: tags,
                threshold: threshold,
                externalRef: externalRef,
                copay: copay,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a rolling inventory schedule in status idle.
    static func newRollingInventorySchedule(_ code: String, label: String) -> RollingInventorySchedule {
        return RollingInventorySchedule(
            code: code,
            label: label,
            clinicianID: "",
            refills: 0,
            retries: 0,
            region: "",
            tags: [],
            threshold: 0.0,
            externalRef: "",
            copay: 0.0,
            limit: 0,
            status: RollingInventoryScheduleStatus.idle
        )
    }
}
