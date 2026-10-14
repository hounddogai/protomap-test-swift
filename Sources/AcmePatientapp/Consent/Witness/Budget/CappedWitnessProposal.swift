import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped witness proposal is in its life cycle.
    enum CappedWitnessProposalStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a capped witness proposal and its current status.
    final class CappedWitnessProposal {
        var code: String
        var name: String
        var unit: String
        var graceDays: Int
        var archived: Bool
        var phone: String
        var refills: Int
        var sequence: Int
        var acuity: Int
        var version: Int
        var expiresAt: Int
        var status: CappedWitnessProposalStatus

        init(code: String, name: String, unit: String, graceDays: Int, archived: Bool, phone: String, refills: Int, sequence: Int, acuity: Int, version: Int, expiresAt: Int, status: CappedWitnessProposalStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.graceDays = graceDays
            self.archived = archived
            self.phone = phone
            self.refills = refills
            self.sequence = sequence
            self.acuity = acuity
            self.version = version
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: CappedWitnessProposalStatus) -> Bool {
            switch status {
            case .new:
                return next == CappedWitnessProposalStatus.running || next == CappedWitnessProposalStatus.failed
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CappedWitnessProposalStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedWitnessProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped witness proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedLoad() -> Double {
            return (Double(refills) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> CappedWitnessProposal {
            return CappedWitnessProposal(
                code: code,
                name: name,
                unit: unit,
                graceDays: graceDays,
                archived: archived,
                phone: phone,
                refills: refills,
                sequence: sequence,
                acuity: acuity,
                version: version,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a capped witness proposal in status new.
    static func newCappedWitnessProposal(_ code: String, name: String) -> CappedWitnessProposal {
        return CappedWitnessProposal(
            code: code,
            name: name,
            unit: "",
            graceDays: 0,
            archived: false,
            phone: "",
            refills: 0,
            sequence: 0,
            acuity: 0,
            version: 0,
            expiresAt: 0,
            status: CappedWitnessProposalStatus.new
        )
    }
}
