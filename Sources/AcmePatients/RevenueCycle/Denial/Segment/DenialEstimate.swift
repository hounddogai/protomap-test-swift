import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial estimate is in its life cycle.
    enum DenialEstimateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One denial estimate, with what the planners need to act on it.
    final class DenialEstimate {
        var code: String
        var label: String
        var segment: String
        var notes: String
        var approved: Bool
        var version: Int
        var encounterID: String
        var status: DenialEstimateStatus

        init(code: String, label: String, segment: String, notes: String, approved: Bool, version: Int, encounterID: String, status: DenialEstimateStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.notes = notes
            self.approved = approved
            self.version = version
            self.encounterID = encounterID
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

        func canMoveTo(_ next: DenialEstimateStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DenialEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("denial estimate") \(code)"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> DenialEstimate {
            return DenialEstimate(
                code: code,
                label: label,
                segment: segment,
                notes: notes,
                approved: approved,
                version: version,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a denial estimate in status idle.
    static func newDenialEstimate(_ code: String, label: String) -> DenialEstimate {
        return DenialEstimate(
            code: code,
            label: label,
            segment: "",
            notes: "",
            approved: false,
            version: 0,
            encounterID: "",
            status: DenialEstimateStatus.idle
        )
    }
}
