import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census group is in its life cycle.
    enum CensusGroupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a census group and its current status.
    final class CensusGroup {
        var code: String
        var title: String
        var capacity: Int
        var label: String
        var segment: String
        var copay: Double
        var contactEmail: String
        var bed: String
        var version: Int
        var status: CensusGroupStatus

        init(code: String, title: String, capacity: Int, label: String, segment: String, copay: Double, contactEmail: String, bed: String, version: Int, status: CensusGroupStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.label = label
            self.segment = segment
            self.copay = copay
            self.contactEmail = contactEmail
            self.bed = bed
            self.version = version
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

        func canMoveTo(_ next: CensusGroupStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == CensusGroupStatus.running || next == CensusGroupStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CensusGroupStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("census group") \(code)"
        }

        func effectiveVolume() -> Double {
            return (Double(capacity) * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> CensusGroup {
            return CensusGroup(
                code: code,
                title: title,
                capacity: capacity,
                label: label,
                segment: segment,
                copay: copay,
                contactEmail: contactEmail,
                bed: bed,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a census group in status new.
    static func newCensusGroup(_ code: String, title: String) -> CensusGroup {
        return CensusGroup(
            code: code,
            title: title,
            capacity: 0,
            label: "",
            segment: "",
            copay: 0.0,
            contactEmail: "",
            bed: "",
            version: 0,
            status: CensusGroupStatus.new
        )
    }
}
