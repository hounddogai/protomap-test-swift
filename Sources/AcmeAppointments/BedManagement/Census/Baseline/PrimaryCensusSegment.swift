import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary census segment is in its life cycle.
    enum PrimaryCensusSegmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A primary census segment as the census team keeps it.
    final class PrimaryCensusSegment {
        var code: String
        var label: String
        var amount: Double
        var priority: Int
        var encounterID: String
        var externalRef: String
        var source: String
        var approved: Bool
        var clinicianID: String
        var floorValue: Double
        var status: PrimaryCensusSegmentStatus

        init(code: String, label: String, amount: Double, priority: Int, encounterID: String, externalRef: String, source: String, approved: Bool, clinicianID: String, floorValue: Double, status: PrimaryCensusSegmentStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.priority = priority
            self.encounterID = encounterID
            self.externalRef = externalRef
            self.source = source
            self.approved = approved
            self.clinicianID = clinicianID
            self.floorValue = floorValue
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

        func canMoveTo(_ next: PrimaryCensusSegmentStatus) -> Bool {
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
                return next == PrimaryCensusSegmentStatus.ready
            case .ready:
                return next == PrimaryCensusSegmentStatus.draining
            case .draining:
                return next == PrimaryCensusSegmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryCensusSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary census segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedExposure() -> Double {
            return ((Double(priority) + amount) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryCensusSegment {
            return PrimaryCensusSegment(
                code: code,
                label: label,
                amount: amount,
                priority: priority,
                encounterID: encounterID,
                externalRef: externalRef,
                source: source,
                approved: approved,
                clinicianID: clinicianID,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a primary census segment in status idle.
    static func newPrimaryCensusSegment(_ code: String, label: String) -> PrimaryCensusSegment {
        return PrimaryCensusSegment(
            code: code,
            label: label,
            amount: 0.0,
            priority: 0,
            encounterID: "",
            externalRef: "",
            source: "",
            approved: false,
            clinicianID: "",
            floorValue: 0.0,
            status: PrimaryCensusSegmentStatus.idle
        )
    }
}
