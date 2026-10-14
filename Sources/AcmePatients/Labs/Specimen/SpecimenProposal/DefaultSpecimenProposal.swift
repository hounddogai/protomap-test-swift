import AcmePlatform
import Foundation

extension Labs {
    /// Where a default specimen proposal is in its life cycle.
    enum DefaultSpecimenProposalStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One default specimen proposal, with what the planners need to act on it.
    final class DefaultSpecimenProposal {
        var code: String
        var name: String
        var archived: Bool
        var batchSize: Int
        var ward: String
        var currency: String
        var active: Bool
        var status: DefaultSpecimenProposalStatus

        init(code: String, name: String, archived: Bool, batchSize: Int, ward: String, currency: String, active: Bool, status: DefaultSpecimenProposalStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.batchSize = batchSize
            self.ward = ward
            self.currency = currency
            self.active = active
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

        func canMoveTo(_ next: DefaultSpecimenProposalStatus) -> Bool {
            switch status {
            case .new:
                return next == DefaultSpecimenProposalStatus.queued || next == DefaultSpecimenProposalStatus.running
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == DefaultSpecimenProposalStatus.done
            case .done:
                return next == DefaultSpecimenProposalStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultSpecimenProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default specimen proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(batchSize)
        }

        func copyValue() -> DefaultSpecimenProposal {
            return DefaultSpecimenProposal(
                code: code,
                name: name,
                archived: archived,
                batchSize: batchSize,
                ward: ward,
                currency: currency,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a default specimen proposal in status new.
    static func newDefaultSpecimenProposal(_ code: String, name: String) -> DefaultSpecimenProposal {
        return DefaultSpecimenProposal(
            code: code,
            name: name,
            archived: false,
            batchSize: 0,
            ward: "",
            currency: "",
            active: false,
            status: DefaultSpecimenProposalStatus.new
        )
    }
}
