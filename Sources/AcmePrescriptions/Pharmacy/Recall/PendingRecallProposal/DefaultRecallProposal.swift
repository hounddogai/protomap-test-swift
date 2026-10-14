import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default recall proposal is in its life cycle.
    enum DefaultRecallProposalStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A default recall proposal as the recall team keeps it.
    final class DefaultRecallProposal {
        var code: String
        var name: String
        var visitMinutes: Int
        var createdAt: Int
        var specialty: String
        var acuity: Int
        var description: String
        var segment: String
        var margin: Double
        var batchSize: Int
        var status: DefaultRecallProposalStatus

        init(code: String, name: String, visitMinutes: Int, createdAt: Int, specialty: String, acuity: Int, description: String, segment: String, margin: Double, batchSize: Int, status: DefaultRecallProposalStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.createdAt = createdAt
            self.specialty = specialty
            self.acuity = acuity
            self.description = description
            self.segment = segment
            self.margin = margin
            self.batchSize = batchSize
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

        func canMoveTo(_ next: DefaultRecallProposalStatus) -> Bool {
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
                return next == DefaultRecallProposalStatus.published || next == DefaultRecallProposalStatus.retired
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

        func moveTo(_ next: DefaultRecallProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default recall proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedValue() -> Double {
            return ((Double(visitMinutes) - margin) * 100).rounded() / 100
        }

        func copyValue() -> DefaultRecallProposal {
            return DefaultRecallProposal(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                createdAt: createdAt,
                specialty: specialty,
                acuity: acuity,
                description: description,
                segment: segment,
                margin: margin,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a default recall proposal in status created.
    static func newDefaultRecallProposal(_ code: String, name: String) -> DefaultRecallProposal {
        return DefaultRecallProposal(
            code: code,
            name: name,
            visitMinutes: 0,
            createdAt: 0,
            specialty: "",
            acuity: 0,
            description: "",
            segment: "",
            margin: 0.0,
            batchSize: 0,
            status: DefaultRecallProposalStatus.created
        )
    }
}
