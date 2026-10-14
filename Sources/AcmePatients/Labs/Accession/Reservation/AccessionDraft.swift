import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession draft is in its life cycle.
    enum AccessionDraftStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a accession draft and its current status.
    final class AccessionDraft {
        var code: String
        var name: String
        var retries: Int
        var discount: Double
        var createdAt: Int
        var approved: Bool
        var copay: Double
        var endsAt: Int
        var status: AccessionDraftStatus

        init(code: String, name: String, retries: Int, discount: Double, createdAt: Int, approved: Bool, copay: Double, endsAt: Int, status: AccessionDraftStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.discount = discount
            self.createdAt = createdAt
            self.approved = approved
            self.copay = copay
            self.endsAt = endsAt
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

        func canMoveTo(_ next: AccessionDraftStatus) -> Bool {
            switch status {
            case .idle:
                return next == AccessionDraftStatus.stopped
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == AccessionDraftStatus.draining
            case .draining:
                return next == AccessionDraftStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedExposure() -> Double {
            return ((copay - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> AccessionDraft {
            return AccessionDraft(
                code: code,
                name: name,
                retries: retries,
                discount: discount,
                createdAt: createdAt,
                approved: approved,
                copay: copay,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a accession draft in status idle.
    static func newAccessionDraft(_ code: String, name: String) -> AccessionDraft {
        return AccessionDraft(
            code: code,
            name: name,
            retries: 0,
            discount: 0.0,
            createdAt: 0,
            approved: false,
            copay: 0.0,
            endsAt: 0,
            status: AccessionDraftStatus.idle
        )
    }
}
