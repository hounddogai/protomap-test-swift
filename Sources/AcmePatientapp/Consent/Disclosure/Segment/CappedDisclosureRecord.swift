import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped disclosure record is in its life cycle.
    enum CappedDisclosureRecordStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A capped disclosure record. Its code is unique within a tenant.
    final class CappedDisclosureRecord {
        var code: String
        var label: String
        var region: String
        var priority: Int
        var ratio: Double
        var clinicianID: String
        var startsAt: Int
        var status: CappedDisclosureRecordStatus

        init(code: String, label: String, region: String, priority: Int, ratio: Double, clinicianID: String, startsAt: Int, status: CappedDisclosureRecordStatus) {
            self.code = code
            self.label = label
            self.region = region
            self.priority = priority
            self.ratio = ratio
            self.clinicianID = clinicianID
            self.startsAt = startsAt
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

        func canMoveTo(_ next: CappedDisclosureRecordStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == CappedDisclosureRecordStatus.draining
            case .ready:
                return next == CappedDisclosureRecordStatus.stopped
            case .draining:
                return next == CappedDisclosureRecordStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedDisclosureRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped disclosure record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveVolume() -> Double {
            return (Double(priority) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> CappedDisclosureRecord {
            return CappedDisclosureRecord(
                code: code,
                label: label,
                region: region,
                priority: priority,
                ratio: ratio,
                clinicianID: clinicianID,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a capped disclosure record in status idle.
    static func newCappedDisclosureRecord(_ code: String, label: String) -> CappedDisclosureRecord {
        return CappedDisclosureRecord(
            code: code,
            label: label,
            region: "",
            priority: 0,
            ratio: 0.0,
            clinicianID: "",
            startsAt: 0,
            status: CappedDisclosureRecordStatus.idle
        )
    }
}
