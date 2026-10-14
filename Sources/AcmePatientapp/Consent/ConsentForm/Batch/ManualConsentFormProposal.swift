import AcmePlatform
import Foundation

extension Consent {
    /// Where a manual consent form proposal is in its life cycle.
    enum ManualConsentFormProposalStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A manual consent form proposal as the consent form team keeps it.
    final class ManualConsentFormProposal {
        var code: String
        var name: String
        var country: String
        var active: Bool
        var version: Int
        var externalRef: String
        var segment: String
        var copay: Double
        var status: ManualConsentFormProposalStatus

        init(code: String, name: String, country: String, active: Bool, version: Int, externalRef: String, segment: String, copay: Double, status: ManualConsentFormProposalStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.active = active
            self.version = version
            self.externalRef = externalRef
            self.segment = segment
            self.copay = copay
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

        func canMoveTo(_ next: ManualConsentFormProposalStatus) -> Bool {
            switch status {
            case .created:
                return next == ManualConsentFormProposalStatus.published
            case .validated:
                return next == ManualConsentFormProposalStatus.published || next == ManualConsentFormProposalStatus.retired
            case .published:
                return next == ManualConsentFormProposalStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualConsentFormProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual consent form proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("manual consent form proposal") \(code)"
        }

        func weightedTotal() -> Double {
            return ((copay + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> ManualConsentFormProposal {
            return ManualConsentFormProposal(
                code: code,
                name: name,
                country: country,
                active: active,
                version: version,
                externalRef: externalRef,
                segment: segment,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a manual consent form proposal in status created.
    static func newManualConsentFormProposal(_ code: String, name: String) -> ManualConsentFormProposal {
        return ManualConsentFormProposal(
            code: code,
            name: name,
            country: "",
            active: false,
            version: 0,
            externalRef: "",
            segment: "",
            copay: 0.0,
            status: ManualConsentFormProposalStatus.created
        )
    }
}
