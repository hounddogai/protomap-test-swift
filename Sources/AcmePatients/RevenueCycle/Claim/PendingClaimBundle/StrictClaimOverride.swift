import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a strict claim override is in its life cycle.
    enum StrictClaimOverrideStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One strict claim override, with what the planners need to act on it.
    final class StrictClaimOverride {
        var code: String
        var title: String
        var summary: String
        var facility: String
        var diagnosisCode: String
        var approved: Bool
        var version: Int
        var sequence: Int
        var description: String
        var checksum: String
        var ceiling: Double
        var status: StrictClaimOverrideStatus

        init(code: String, title: String, summary: String, facility: String, diagnosisCode: String, approved: Bool, version: Int, sequence: Int, description: String, checksum: String, ceiling: Double, status: StrictClaimOverrideStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.facility = facility
            self.diagnosisCode = diagnosisCode
            self.approved = approved
            self.version = version
            self.sequence = sequence
            self.description = description
            self.checksum = checksum
            self.ceiling = ceiling
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

        func canMoveTo(_ next: StrictClaimOverrideStatus) -> Bool {
            switch status {
            case .new:
                return next == StrictClaimOverrideStatus.queued
            case .queued:
                return next == StrictClaimOverrideStatus.running
            case .running:
                return next == StrictClaimOverrideStatus.done || next == StrictClaimOverrideStatus.failed
            case .done:
                return next == StrictClaimOverrideStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictClaimOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict claim override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedTotal() -> Double {
            return ((ceiling - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> StrictClaimOverride {
            return StrictClaimOverride(
                code: code,
                title: title,
                summary: summary,
                facility: facility,
                diagnosisCode: diagnosisCode,
                approved: approved,
                version: version,
                sequence: sequence,
                description: description,
                checksum: checksum,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a strict claim override in status new.
    static func newStrictClaimOverride(_ code: String, title: String) -> StrictClaimOverride {
        return StrictClaimOverride(
            code: code,
            title: title,
            summary: "",
            facility: "",
            diagnosisCode: "",
            approved: false,
            version: 0,
            sequence: 0,
            description: "",
            checksum: "",
            ceiling: 0.0,
            status: StrictClaimOverrideStatus.new
        )
    }
}
