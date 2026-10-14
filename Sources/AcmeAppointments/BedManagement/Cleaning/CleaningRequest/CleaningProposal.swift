import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning proposal is in its life cycle.
    enum CleaningProposalStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A cleaning proposal as the cleaning team keeps it.
    final class CleaningProposal {
        var code: String
        var label: String
        var source: String
        var threshold: Double
        var limit: Int
        var patientRef: String
        var windowDays: Int
        var channel: String
        var margin: Double
        var status: CleaningProposalStatus

        init(code: String, label: String, source: String, threshold: Double, limit: Int, patientRef: String, windowDays: Int, channel: String, margin: Double, status: CleaningProposalStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.threshold = threshold
            self.limit = limit
            self.patientRef = patientRef
            self.windowDays = windowDays
            self.channel = channel
            self.margin = margin
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CleaningProposalStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == CleaningProposalStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: CleaningProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("cleaning proposal") \(code)"
        }

        func adjustedValue() -> Double {
            return ((margin - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> CleaningProposal {
            return CleaningProposal(
                code: code,
                label: label,
                source: source,
                threshold: threshold,
                limit: limit,
                patientRef: patientRef,
                windowDays: windowDays,
                channel: channel,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a cleaning proposal in status created.
    static func newCleaningProposal(_ code: String, label: String) -> CleaningProposal {
        return CleaningProposal(
            code: code,
            label: label,
            source: "",
            threshold: 0.0,
            limit: 0,
            patientRef: "",
            windowDays: 0,
            channel: "",
            margin: 0.0,
            status: CleaningProposalStatus.created
        )
    }
}
