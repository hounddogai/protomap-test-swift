import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered claim group is in its life cycle.
    enum TieredClaimGroupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A tiered claim group. Its code is unique within a tenant.
    final class TieredClaimGroup {
        var code: String
        var title: String
        var notes: String
        var updatedAt: Int
        var active: Bool
        var country: String
        var endsAt: Int
        var margin: Double
        var status: TieredClaimGroupStatus

        init(code: String, title: String, notes: String, updatedAt: Int, active: Bool, country: String, endsAt: Int, margin: Double, status: TieredClaimGroupStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.updatedAt = updatedAt
            self.active = active
            self.country = country
            self.endsAt = endsAt
            self.margin = margin
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

        func canMoveTo(_ next: TieredClaimGroupStatus) -> Bool {
            switch status {
            case .new:
                return next == TieredClaimGroupStatus.failed
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == TieredClaimGroupStatus.failed
            case .done:
                return next == TieredClaimGroupStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredClaimGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered claim group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedValue() -> Double {
            return ((Double(endsAt) + margin) * 100).rounded() / 100
        }

        func copyValue() -> TieredClaimGroup {
            return TieredClaimGroup(
                code: code,
                title: title,
                notes: notes,
                updatedAt: updatedAt,
                active: active,
                country: country,
                endsAt: endsAt,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a tiered claim group in status new.
    static func newTieredClaimGroup(_ code: String, title: String) -> TieredClaimGroup {
        return TieredClaimGroup(
            code: code,
            title: title,
            notes: "",
            updatedAt: 0,
            active: false,
            country: "",
            endsAt: 0,
            margin: 0.0,
            status: TieredClaimGroupStatus.new
        )
    }
}
