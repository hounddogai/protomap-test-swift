import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled proxy proposal is in its life cycle.
    enum ScheduledProxyProposalStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A scheduled proxy proposal as the proxy team keeps it.
    final class ScheduledProxyProposal {
        var code: String
        var label: String
        var rate: Double
        var version: Int
        var patientRef: String
        var title: String
        var diagnosisCode: String
        var tags: [String]
        var status: ScheduledProxyProposalStatus

        init(code: String, label: String, rate: Double, version: Int, patientRef: String, title: String, diagnosisCode: String, tags: [String], status: ScheduledProxyProposalStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.version = version
            self.patientRef = patientRef
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.tags = tags
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

        func canMoveTo(_ next: ScheduledProxyProposalStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ScheduledProxyProposalStatus.withdrawn
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

        func moveTo(_ next: ScheduledProxyProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled proxy proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedExposure() -> Double {
            return ((rate - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledProxyProposal {
            return ScheduledProxyProposal(
                code: code,
                label: label,
                rate: rate,
                version: version,
                patientRef: patientRef,
                title: title,
                diagnosisCode: diagnosisCode,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled proxy proposal in status proposed.
    static func newScheduledProxyProposal(_ code: String, label: String) -> ScheduledProxyProposal {
        return ScheduledProxyProposal(
            code: code,
            label: label,
            rate: 0.0,
            version: 0,
            patientRef: "",
            title: "",
            diagnosisCode: "",
            tags: [],
            status: ScheduledProxyProposalStatus.proposed
        )
    }
}
