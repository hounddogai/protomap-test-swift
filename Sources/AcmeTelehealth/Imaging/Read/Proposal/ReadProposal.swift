import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read proposal is in its life cycle.
    enum ReadProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A read proposal. Its code is unique within a tenant.
    final class ReadProposal {
        var code: String
        var name: String
        var summary: String
        var updatedAt: Int
        var windowDays: Int
        var phone: String
        var ward: String
        var maximum: Double
        var label: String
        var archived: Bool
        var status: ReadProposalStatus

        init(code: String, name: String, summary: String, updatedAt: Int, windowDays: Int, phone: String, ward: String, maximum: Double, label: String, archived: Bool, status: ReadProposalStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.updatedAt = updatedAt
            self.windowDays = windowDays
            self.phone = phone
            self.ward = ward
            self.maximum = maximum
            self.label = label
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReadProposalStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ReadProposalStatus.reopened
            case .inReview:
                return next == ReadProposalStatus.resolved
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: ReadProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func netTotal() -> Double {
            return ((Double(windowDays) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> ReadProposal {
            return ReadProposal(
                code: code,
                name: name,
                summary: summary,
                updatedAt: updatedAt,
                windowDays: windowDays,
                phone: phone,
                ward: ward,
                maximum: maximum,
                label: label,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a read proposal in status open.
    static func newReadProposal(_ code: String, name: String) -> ReadProposal {
        return ReadProposal(
            code: code,
            name: name,
            summary: "",
            updatedAt: 0,
            windowDays: 0,
            phone: "",
            ward: "",
            maximum: 0.0,
            label: "",
            archived: false,
            status: ReadProposalStatus.`open`
        )
    }
}
