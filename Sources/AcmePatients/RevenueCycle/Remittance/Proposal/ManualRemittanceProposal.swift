import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual remittance proposal is in its life cycle.
    enum ManualRemittanceProposalStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A manual remittance proposal as the remittance team keeps it.
    final class ManualRemittanceProposal {
        var code: String
        var title: String
        var locale: String
        var rate: Double
        var capacity: Int
        var revision: Int
        var sequence: Int
        var pinned: Bool
        var ceiling: Double
        var status: ManualRemittanceProposalStatus

        init(code: String, title: String, locale: String, rate: Double, capacity: Int, revision: Int, sequence: Int, pinned: Bool, ceiling: Double, status: ManualRemittanceProposalStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.rate = rate
            self.capacity = capacity
            self.revision = revision
            self.sequence = sequence
            self.pinned = pinned
            self.ceiling = ceiling
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

        func canMoveTo(_ next: ManualRemittanceProposalStatus) -> Bool {
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
                return next == ManualRemittanceProposalStatus.done
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ManualRemittanceProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual remittance proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveLoad() -> Double {
            return ((Double(sequence) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> ManualRemittanceProposal {
            return ManualRemittanceProposal(
                code: code,
                title: title,
                locale: locale,
                rate: rate,
                capacity: capacity,
                revision: revision,
                sequence: sequence,
                pinned: pinned,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a manual remittance proposal in status new.
    static func newManualRemittanceProposal(_ code: String, title: String) -> ManualRemittanceProposal {
        return ManualRemittanceProposal(
            code: code,
            title: title,
            locale: "",
            rate: 0.0,
            capacity: 0,
            revision: 0,
            sequence: 0,
            pinned: false,
            ceiling: 0.0,
            status: ManualRemittanceProposalStatus.new
        )
    }
}
