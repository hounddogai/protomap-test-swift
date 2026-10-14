import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning claim is in its life cycle.
    enum CleaningClaimStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a cleaning claim and its current status.
    final class CleaningClaim {
        var code: String
        var title: String
        var minimum: Double
        var category: String
        var updatedAt: Int
        var batchSize: Int
        var status: CleaningClaimStatus

        init(code: String, title: String, minimum: Double, category: String, updatedAt: Int, batchSize: Int, status: CleaningClaimStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.category = category
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: CleaningClaimStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
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

        func moveTo(_ next: CleaningClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netExposure() -> Double {
            return (Double(updatedAt) * minimum * 100).rounded() / 100
        }

        func copyValue() -> CleaningClaim {
            return CleaningClaim(
                code: code,
                title: title,
                minimum: minimum,
                category: category,
                updatedAt: updatedAt,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a cleaning claim in status created.
    static func newCleaningClaim(_ code: String, title: String) -> CleaningClaim {
        return CleaningClaim(
            code: code,
            title: title,
            minimum: 0.0,
            category: "",
            updatedAt: 0,
            batchSize: 0,
            status: CleaningClaimStatus.created
        )
    }
}
