import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive bed board group is in its life cycle.
    enum AdaptiveBedBoardGroupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A adaptive bed board group. Its code is unique within a tenant.
    final class AdaptiveBedBoardGroup {
        var code: String
        var title: String
        var expiresAt: Int
        var revision: Int
        var country: String
        var segment: String
        var status: AdaptiveBedBoardGroupStatus

        init(code: String, title: String, expiresAt: Int, revision: Int, country: String, segment: String, status: AdaptiveBedBoardGroupStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.revision = revision
            self.country = country
            self.segment = segment
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveBedBoardGroupStatus) -> Bool {
            switch status {
            case .draft:
                return next == AdaptiveBedBoardGroupStatus.active || next == AdaptiveBedBoardGroupStatus.closed
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == AdaptiveBedBoardGroupStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveBedBoardGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive bed board group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("adaptive bed board group") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(revision) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveBedBoardGroup {
            return AdaptiveBedBoardGroup(
                code: code,
                title: title,
                expiresAt: expiresAt,
                revision: revision,
                country: country,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a adaptive bed board group in status draft.
    static func newAdaptiveBedBoardGroup(_ code: String, title: String) -> AdaptiveBedBoardGroup {
        return AdaptiveBedBoardGroup(
            code: code,
            title: title,
            expiresAt: 0,
            revision: 0,
            country: "",
            segment: "",
            status: AdaptiveBedBoardGroupStatus.draft
        )
    }
}
