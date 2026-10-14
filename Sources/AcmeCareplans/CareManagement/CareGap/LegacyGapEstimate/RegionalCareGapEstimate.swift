import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional care gap estimate is in its life cycle.
    enum RegionalCareGapEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One regional care gap estimate, with what the planners need to act on it.
    final class RegionalCareGapEstimate {
        var code: String
        var label: String
        var retries: Int
        var sequence: Int
        var tags: [String]
        var notes: String
        var durationMinutes: Int
        var approved: Bool
        var version: Int
        var status: RegionalCareGapEstimateStatus

        init(code: String, label: String, retries: Int, sequence: Int, tags: [String], notes: String, durationMinutes: Int, approved: Bool, version: Int, status: RegionalCareGapEstimateStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.sequence = sequence
            self.tags = tags
            self.notes = notes
            self.durationMinutes = durationMinutes
            self.approved = approved
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

        func canMoveTo(_ next: RegionalCareGapEstimateStatus) -> Bool {
            switch status {
            case .new:
                return next == RegionalCareGapEstimateStatus.queued || next == RegionalCareGapEstimateStatus.failed
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == RegionalCareGapEstimateStatus.failed
            case .done:
                return next == RegionalCareGapEstimateStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalCareGapEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional care gap estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedVolume() -> Double {
            return ((Double(sequence) - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalCareGapEstimate {
            return RegionalCareGapEstimate(
                code: code,
                label: label,
                retries: retries,
                sequence: sequence,
                tags: tags,
                notes: notes,
                durationMinutes: durationMinutes,
                approved: approved,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional care gap estimate in status new.
    static func newRegionalCareGapEstimate(_ code: String, label: String) -> RegionalCareGapEstimate {
        return RegionalCareGapEstimate(
            code: code,
            label: label,
            retries: 0,
            sequence: 0,
            tags: [],
            notes: "",
            durationMinutes: 0,
            approved: false,
            version: 0,
            status: RegionalCareGapEstimateStatus.new
        )
    }
}
