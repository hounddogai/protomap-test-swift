import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary discharge plan proposal is in its life cycle.
    enum PrimaryDischargePlanProposalStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a primary discharge plan proposal and its current status.
    final class PrimaryDischargePlanProposal {
        var code: String
        var name: String
        var dosageMg: Double
        var visitMinutes: Int
        var limit: Int
        var createdAt: Int
        var priority: Int
        var status: PrimaryDischargePlanProposalStatus

        init(code: String, name: String, dosageMg: Double, visitMinutes: Int, limit: Int, createdAt: Int, priority: Int, status: PrimaryDischargePlanProposalStatus) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.visitMinutes = visitMinutes
            self.limit = limit
            self.createdAt = createdAt
            self.priority = priority
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

        func canMoveTo(_ next: PrimaryDischargePlanProposalStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == PrimaryDischargePlanProposalStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryDischargePlanProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary discharge plan proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("primary discharge plan proposal") \(code)"
        }

        func netLoad() -> Double {
            return (dosageMg * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryDischargePlanProposal {
            return PrimaryDischargePlanProposal(
                code: code,
                name: name,
                dosageMg: dosageMg,
                visitMinutes: visitMinutes,
                limit: limit,
                createdAt: createdAt,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary discharge plan proposal in status new.
    static func newPrimaryDischargePlanProposal(_ code: String, name: String) -> PrimaryDischargePlanProposal {
        return PrimaryDischargePlanProposal(
            code: code,
            name: name,
            dosageMg: 0.0,
            visitMinutes: 0,
            limit: 0,
            createdAt: 0,
            priority: 0,
            status: PrimaryDischargePlanProposalStatus.new
        )
    }
}
