import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a fallback discharge plan proposal is in its life cycle.
    enum FallbackDischargePlanProposalStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One fallback discharge plan proposal, with what the planners need to act on it.
    final class FallbackDischargePlanProposal {
        var code: String
        var name: String
        var description: String
        var ward: String
        var diagnosisCode: String
        var endsAt: Int
        var status: FallbackDischargePlanProposalStatus

        init(code: String, name: String, description: String, ward: String, diagnosisCode: String, endsAt: Int, status: FallbackDischargePlanProposalStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.ward = ward
            self.diagnosisCode = diagnosisCode
            self.endsAt = endsAt
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

        func canMoveTo(_ next: FallbackDischargePlanProposalStatus) -> Bool {
            switch status {
            case .new:
                return next == FallbackDischargePlanProposalStatus.queued
            case .queued:
                return next == FallbackDischargePlanProposalStatus.running || next == FallbackDischargePlanProposalStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == FallbackDischargePlanProposalStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackDischargePlanProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback discharge plan proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("fallback discharge plan proposal") \(code)"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> FallbackDischargePlanProposal {
            return FallbackDischargePlanProposal(
                code: code,
                name: name,
                description: description,
                ward: ward,
                diagnosisCode: diagnosisCode,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a fallback discharge plan proposal in status new.
    static func newFallbackDischargePlanProposal(_ code: String, name: String) -> FallbackDischargePlanProposal {
        return FallbackDischargePlanProposal(
            code: code,
            name: name,
            description: "",
            ward: "",
            diagnosisCode: "",
            endsAt: 0,
            status: FallbackDischargePlanProposalStatus.new
        )
    }
}
