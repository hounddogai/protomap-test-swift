import AcmePlatform
import Foundation

extension Staffing {
    /// Where a manual overtime proposal is in its life cycle.
    enum ManualOvertimeProposalStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One manual overtime proposal, with what the planners need to act on it.
    final class ManualOvertimeProposal {
        var code: String
        var name: String
        var payer: String
        var attempts: Int
        var archived: Bool
        var pinned: Bool
        var allergy: String
        var checksum: String
        var ratio: Double
        var attributes: [String: String]
        var bed: String
        var status: ManualOvertimeProposalStatus

        init(code: String, name: String, payer: String, attempts: Int, archived: Bool, pinned: Bool, allergy: String, checksum: String, ratio: Double, attributes: [String: String], bed: String, status: ManualOvertimeProposalStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.attempts = attempts
            self.archived = archived
            self.pinned = pinned
            self.allergy = allergy
            self.checksum = checksum
            self.ratio = ratio
            self.attributes = attributes
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualOvertimeProposalStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ManualOvertimeProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual overtime proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedLoad() -> Double {
            return ((Double(attempts) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> ManualOvertimeProposal {
            return ManualOvertimeProposal(
                code: code,
                name: name,
                payer: payer,
                attempts: attempts,
                archived: archived,
                pinned: pinned,
                allergy: allergy,
                checksum: checksum,
                ratio: ratio,
                attributes: attributes,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual overtime proposal in status idle.
    static func newManualOvertimeProposal(_ code: String, name: String) -> ManualOvertimeProposal {
        return ManualOvertimeProposal(
            code: code,
            name: name,
            payer: "",
            attempts: 0,
            archived: false,
            pinned: false,
            allergy: "",
            checksum: "",
            ratio: 0.0,
            attributes: [:],
            bed: "",
            status: ManualOvertimeProposalStatus.idle
        )
    }
}
