import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive bed board target is in its life cycle.
    enum AdaptiveBedBoardTargetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A adaptive bed board target as the bed board team keeps it.
    final class AdaptiveBedBoardTarget {
        var code: String
        var title: String
        var category: String
        var country: String
        var createdAt: Int
        var externalRef: String
        var status: AdaptiveBedBoardTargetStatus

        init(code: String, title: String, category: String, country: String, createdAt: Int, externalRef: String, status: AdaptiveBedBoardTargetStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.country = country
            self.createdAt = createdAt
            self.externalRef = externalRef
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

        func canMoveTo(_ next: AdaptiveBedBoardTargetStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == AdaptiveBedBoardTargetStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveBedBoardTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive bed board target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(createdAt)
        }

        func copyValue() -> AdaptiveBedBoardTarget {
            return AdaptiveBedBoardTarget(
                code: code,
                title: title,
                category: category,
                country: country,
                createdAt: createdAt,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a adaptive bed board target in status created.
    static func newAdaptiveBedBoardTarget(_ code: String, title: String) -> AdaptiveBedBoardTarget {
        return AdaptiveBedBoardTarget(
            code: code,
            title: title,
            category: "",
            country: "",
            createdAt: 0,
            externalRef: "",
            status: AdaptiveBedBoardTargetStatus.created
        )
    }
}
