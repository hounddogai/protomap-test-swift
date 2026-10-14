import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a legacy assessment proposal is in its life cycle.
    enum LegacyAssessmentProposalStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One legacy assessment proposal, with what the planners need to act on it.
    final class LegacyAssessmentProposal {
        var code: String
        var name: String
        var currency: String
        var discount: Double
        var specialty: String
        var region: String
        var pinned: Bool
        var facility: String
        var startsAt: Int
        var status: LegacyAssessmentProposalStatus

        init(code: String, name: String, currency: String, discount: Double, specialty: String, region: String, pinned: Bool, facility: String, startsAt: Int, status: LegacyAssessmentProposalStatus) {
            self.code = code
            self.name = name
            self.currency = currency
            self.discount = discount
            self.specialty = specialty
            self.region = region
            self.pinned = pinned
            self.facility = facility
            self.startsAt = startsAt
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

        func canMoveTo(_ next: LegacyAssessmentProposalStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == LegacyAssessmentProposalStatus.published || next == LegacyAssessmentProposalStatus.retired
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

        func moveTo(_ next: LegacyAssessmentProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy assessment proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveTotal() -> Double {
            return ((discount - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyAssessmentProposal {
            return LegacyAssessmentProposal(
                code: code,
                name: name,
                currency: currency,
                discount: discount,
                specialty: specialty,
                region: region,
                pinned: pinned,
                facility: facility,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a legacy assessment proposal in status created.
    static func newLegacyAssessmentProposal(_ code: String, name: String) -> LegacyAssessmentProposal {
        return LegacyAssessmentProposal(
            code: code,
            name: name,
            currency: "",
            discount: 0.0,
            specialty: "",
            region: "",
            pinned: false,
            facility: "",
            startsAt: 0,
            status: LegacyAssessmentProposalStatus.created
        )
    }
}
